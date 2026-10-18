terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}

# Subscription comes from the active Azure CLI session (az account show),
# so no subscription ID is hardcoded in the repository
provider "azurerm" {
  features {}
}
