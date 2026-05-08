provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_auto" {
  name     = "rg-automation-project"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-auto"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_auto.location
  resource_group_name = azurerm_resource_group.rg_auto.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg_auto.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-auto"
  location            = azurerm_resource_group.rg_auto.location
  resource_group_name = azurerm_resource_group.rg_auto.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-dev-auto"
  resource_group_name = azurerm_resource_group.rg_auto.name
  location            = azurerm_resource_group.rg_auto.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # this is impoprtant
  tags = {
    Environment = "Dev"
    AutoShutdown = "True"
  }
}