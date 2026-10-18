#!/usr/bin/env bash
# Registers the resource providers the project needs and creates the storage account
# that holds Terraform state.
# Terraform cannot create the backend it stores its own state in, so this runs once
# with the Azure CLI. Safe to rerun: every step converges to the same result.
# Requires an authenticated Azure CLI (az login).
# Usage: bash bootstrap/create-state-storage.sh
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-tfstate}"
LOCATION="${LOCATION:-swedencentral}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"
STATE_RETENTION_DAYS=7
# azurerm 5.x registers no resource providers by default. Registering them here keeps
# that subscription-level permission out of the identity that later runs Terraform.
RESOURCE_PROVIDERS=(Microsoft.Storage Microsoft.Network Microsoft.ContainerService Microsoft.DBforPostgreSQL)

for namespace in "${RESOURCE_PROVIDERS[@]}"; do
  echo "Registering resource provider '${namespace}'..."
  az provider register --namespace "${namespace}" --wait --output none
done

# Storage account names are globally unique. A suffix derived from the subscription
# keeps the name stable across reruns without publishing the subscription ID.
SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
SUFFIX="$(printf '%s' "${SUBSCRIPTION_ID}" | sha256sum | cut -c1-8)"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-sttfstate${SUFFIX}}"

echo "Creating resource group '${RESOURCE_GROUP}'..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags project=azure-aks-platform purpose=terraform-state \
  --output none

# Shared key access is disabled so the only way in is an Entra ID identity with a data role
echo "Creating storage account '${STORAGE_ACCOUNT}'..."
az storage account create \
  --name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --output none

# Versioning and soft delete make a corrupted or deleted state file recoverable
az storage account blob-service-properties update \
  --account-name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days "${STATE_RETENTION_DAYS}" \
  --output none

# Created through the management plane, so it works before the data role below propagates
az storage container-rm create \
  --name "${CONTAINER_NAME}" \
  --storage-account "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --output none

STORAGE_ACCOUNT_ID="$(az storage account show \
  --name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query id --output tsv)"
USER_OBJECT_ID="$(az ad signed-in-user show --query id --output tsv)"

# Read/write on blobs only; no rights to change the account itself.
# MSYS_NO_PATHCONV stops Git Bash from rewriting the /subscriptions/... scope into a Windows path.
echo "Granting 'Storage Blob Data Contributor' to the signed-in user..."
MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee-object-id "${USER_OBJECT_ID}" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "${STORAGE_ACCOUNT_ID}" \
  --output none

echo
echo "Backend settings:"
echo "  resource_group_name  = \"${RESOURCE_GROUP}\""
echo "  storage_account_name = \"${STORAGE_ACCOUNT}\""
echo "  container_name       = \"${CONTAINER_NAME}\""
echo "Role assignments can take a few minutes to propagate."
