# Create a Data Factory instance
resource "azurerm_data_factory" "data_factory" {
  name                = "secured-aml-datafactory"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name

  identity {
      type = "SystemAssigned"
  }
}