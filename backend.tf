# Created by bootstrap/create-state-storage.sh. Backend blocks cannot reference
# variables because they are read before anything else is evaluated.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateac92e6ef"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
    # Shared key access is disabled on the account, so authenticate with Entra ID
    use_azuread_auth = true
  }
}
