resource "random_integer" "storage_id" {
  min     = 1
  max     = 9999
}

# Create the ADLS Gen2 Storage account
resource "azurerm_storage_account" "data_lake" {
  name                      = "datalake${random_integer.storage_id.result}"
  resource_group_name       = azurerm_resource_group.project_rg.name
  location                  = azurerm_resource_group.project_rg.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  access_tier               = "Hot"
  enable_https_traffic_only = true
  is_hns_enabled            = true

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.azureml_subnet.id, azurerm_subnet.private_subnet.id]
    bypass                     = ["AzureServices"]
  }

  depends_on = [
    azurerm_subnet.azureml_subnet,
    azurerm_subnet.private_subnet
  ]
}