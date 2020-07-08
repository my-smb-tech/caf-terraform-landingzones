variable "sqldb_username" {
  default = "testadmin"
}

variable "sqldb_password" {
  default = "Password1234!"
}

resource "random_integer" "sqldb_id" {
  min     = 1
  max     = 9999
}

# Create a supporting storage account for SQL Server
# that will be used for SQL auditing and threat detection
resource "azurerm_storage_account" "sql_storage" {
  name                     = "sqlstorage${random_integer.sqldb_id.result}"
  resource_group_name      = azurerm_resource_group.project_rg.name
  location                 = azurerm_resource_group.project_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a SQL Server
resource "azurerm_sql_server" "sql_server" {
  name                         = "sqlserver${random_integer.sqldb_id.result}"
  resource_group_name          = azurerm_resource_group.project_rg.name
  location                     = azurerm_resource_group.project_rg.location
  version                      = "12.0"
  administrator_login          = var.sqldb_username
  administrator_login_password = var.sqldb_password

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.sql_storage.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.sql_storage.primary_access_key
    storage_account_access_key_is_secondary = false
    retention_in_days                       = 6
  }
}

# Allow network traffic to the SQL Server only with resources in the private-subnet 
resource "azurerm_sql_virtual_network_rule" "sql_network_rule" {
  name                = "sql-network-rule"
  resource_group_name = azurerm_resource_group.project_rg.name
  server_name         = azurerm_sql_server.sql_server.name
  subnet_id           = azurerm_subnet.private_subnet.id
}

# Allow only Azure Trusted Services to access the SQL Server 
resource "azurerm_sql_firewall_rule" "sql_firewall_rule" {
  name                = "sql-firewall-rule"
  resource_group_name = azurerm_resource_group.project_rg.name
  server_name         = azurerm_sql_server.sql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Create the Azure SQL Database
resource "azurerm_sql_database" "sql_database" {
  name                             = "secured-aml-db"
  resource_group_name              = azurerm_resource_group.project_rg.name
  location                         = azurerm_resource_group.project_rg.location
  server_name                      = azurerm_sql_server.sql_server.name
  create_mode                      = "Default"
  edition                          = "Standard"
  requested_service_objective_name = "S1"
}