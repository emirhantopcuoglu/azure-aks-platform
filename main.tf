resource "azurerm_resource_group" "main" {
  name     = "rg-aks-platform-dev"
  location = "swedencentral"

  tags = {
    project     = "azure-aks-platform"
    environment = "dev"
    managed_by  = "terraform"
  }
}
