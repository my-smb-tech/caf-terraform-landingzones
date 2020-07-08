variable "vnet_address_space" {
  default = "10.10.128.0/24"
}

variable "azureml_subnet_prefix" {
  default = "10.10.128.0/26"
}

variable "private_subnet_prefix" {
  default = "10.10.128.64/27"
}

variable "bastion_subnet_prefix" {
  default = "10.10.128.224/27"
}

locals {
  # Service endpoints to enable in the subnets that are created.
  azureml_subnet_service_endpoints = [
    "Microsoft.Storage", "Microsoft.KeyVault"
  ]
  private_subnet_service_endpoints = [
    "Microsoft.Storage", "Microsoft.Sql"
  ]
}

# Create the VNet
resource "azurerm_virtual_network" "project_vnet" {
  name                = "secured-aml-vnet"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  address_space       = [var.vnet_address_space]
}

# Create the azureml-subnet
resource "azurerm_subnet" "azureml_subnet" {
  name                      = "azureml-subnet"
  resource_group_name       = azurerm_resource_group.project_rg.name
  virtual_network_name      = azurerm_virtual_network.project_vnet.name
  address_prefix            = var.azureml_subnet_prefix
  service_endpoints         = local.azureml_subnet_service_endpoints
}

# Create the private-subnet
resource "azurerm_subnet" "private_subnet" {
  name                      = "private-subnet"
  resource_group_name       = azurerm_resource_group.project_rg.name
  virtual_network_name      = azurerm_virtual_network.project_vnet.name
  address_prefix            = var.private_subnet_prefix
  service_endpoints         = local.private_subnet_service_endpoints
}

# Create the AzureBastionSubnet
resource "azurerm_subnet" "bastion_subnet" {
  name                      = "AzureBastionSubnet"
  resource_group_name       = azurerm_resource_group.project_rg.name
  virtual_network_name      = azurerm_virtual_network.project_vnet.name
  address_prefix            = var.bastion_subnet_prefix
}

# Create the Network Security Group (NSG) for the Azure ML subnet
# The subnet must allow inbound communication from the Batch service,
# because Machine Learning Compute currently uses the Azure Batch service
# to provision VMs in the specified virtual network.
resource "azurerm_network_security_group" "azureml_subnet_nsg" {
  name                = "azureml-subnet-nsg"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name

  security_rule {
    name                       = "AllowBatchInBound"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29876-29877"
    source_address_prefix      = "BatchNodeManagement"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMLInBound"
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "44224"
    source_address_prefix      = "AzureMachineLearning"
    destination_address_prefix = "*"
  }
}

# Associate the NSG to the Azure ML subnet
resource "azurerm_subnet_network_security_group_association" "azureml_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.azureml_subnet.id
  network_security_group_id = azurerm_network_security_group.azureml_subnet_nsg.id
}

# Create a public IP address for the Azure Bastion
resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "secured-aml-vnet-bastion-host-ip"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the Bastion Host
resource "azurerm_bastion_host" "bastion_host" {
  name                = "secured-aml-vnet-bastion-host"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}