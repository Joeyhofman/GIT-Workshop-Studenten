terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id = "c064671c-8f74-4fec-b088-b53c568245eb"
}

data "azurerm_ssh_public_key" "skylab" {
  name                = "skylab"
  resource_group_name = "S1188419"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ubuntu"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "S1188419"
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-ubuntu"
  resource_group_name  = "S1188419"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-ubuntu"
  location            = "West Europe"
  resource_group_name = "S1188419"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-ubuntu"
  location            = "West Europe"
  resource_group_name = "S1188419"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "ubuntu-vm"
  resource_group_name = "S1188419"
  location            = "West Europe"
  size                = "Standard_DS1_v2"
  admin_username      = "terraform"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "terraform"
    public_key = data.azurerm_ssh_public_key.skylab.public_key
  }
}

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
