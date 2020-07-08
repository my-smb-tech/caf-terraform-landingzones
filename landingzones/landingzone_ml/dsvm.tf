variable "dev_vm_username" {
  default = "testadmin"
}

variable "dev_vm_password" {
  default = "Password1234!"
}

# Create a network interface for the development VM
resource "azurerm_network_interface" "dev_vm_nic" {
  name                = "dev-vm-nic"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create the Network Security Group (NSG) for the development VM.
# It allows direct RDP access to the VM - but since the VM is given
# only a private IP address, the connection to the VM can only
# happen through the Bastion Host we have setup in the VNet where
# the VM is also deployed.
resource "azurerm_network_security_group" "dev_vm_nsg" {
  name                = "dev-vm-nsg"
  location            = azurerm_resource_group.project_rg.location
  resource_group_name = azurerm_resource_group.project_rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate the NSG to the network interface of the development VM
resource "azurerm_network_interface_security_group_association" "dev_vm_nsg_association" {
  network_interface_id      = azurerm_network_interface.dev_vm_nic.id
  network_security_group_id = azurerm_network_security_group.dev_vm_nsg.id
}

# Create the development VM.
# This is the VM that will provide Power BI Desktop, Azure Storage Explorer,
# SQL Server Management Studio, and other tools.
# Hence we instantiate a Data Science VM (Azure DSVM), that comes with these
# tools pre-installed.
resource "azurerm_virtual_machine" "dev_vm" {
  name                  = "dev-vm"
  location              = azurerm_resource_group.project_rg.location
  resource_group_name   = azurerm_resource_group.project_rg.name
  network_interface_ids = [azurerm_network_interface.dev_vm_nic.id]
  vm_size               = "Standard_DS3_v2"

  # Comment this line to keep the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Comment this line to keep the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "dsvm-windows"
    sku       = "server-2016"
    version   = "latest"
  }
  os_profile {
    computer_name  = "dev-vm"
    admin_username = var.dev_vm_username
    admin_password = var.dev_vm_password
  }
  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
  identity {
      type = "SystemAssigned"
  }
  storage_os_disk {
    name              = "dev-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  storage_data_disk {
    name              = "dev-vm-datadisk"
    caching           = "ReadWrite"
    create_option     = "Empty"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = 1024
    lun               = 0
  }
}