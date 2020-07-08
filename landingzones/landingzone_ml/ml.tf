resource "random_integer" "aml_id" {
  min     = 1
  max     = 9999
}

# Create an Application Insights instance to be used by Azure Machine Learning
resource "azurerm_application_insights" "aml_app_insights" {
  name                = "amlapp${random_integer.aml_id.result}"
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location
  application_type    = "web"
}

# Create a Key Vault to be used by Azure Machine Learning
resource "azurerm_key_vault" "aml_key_vault" {
  name                = "amlkv${random_integer.aml_id.result}"
  resource_group_name = azurerm_resource_group.project_rg.name
  location            = azurerm_resource_group.project_rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"

  network_acls {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.azureml_subnet.id]
    bypass                     = "AzureServices"
  }

  depends_on = [
    azurerm_subnet.azureml_subnet
  ]
}

# Create a supporting storage account for Azure Machine Learning
resource "azurerm_storage_account" "aml_storage" {
  name                     = "amlstorage${random_integer.aml_id.result}"
  resource_group_name      = azurerm_resource_group.project_rg.name
  location                 = azurerm_resource_group.project_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

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

resource "azurerm_machine_learning_workspace" "aml_workspace" {
  name                    = "secured-aml-workspace"
  resource_group_name     = azurerm_resource_group.project_rg.name
  location                = azurerm_resource_group.project_rg.location
  sku_name                = "Enterprise"
  application_insights_id = azurerm_application_insights.aml_app_insights.id
  key_vault_id            = azurerm_key_vault.aml_key_vault.id
  storage_account_id      = azurerm_storage_account.aml_storage.id

  identity {
    type = "SystemAssigned"
  }
}