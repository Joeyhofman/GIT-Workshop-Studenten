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
  subscription_id = var.subscription_id
}

data "azurerm_ssh_public_key" "skylab" {
  name                = var.ssh_key_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ubuntu"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-ubuntu"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  count               = var.vm_count
  name                = "pip-ubuntu-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "nic-ubuntu-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "ubuntu-vm-${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = "iac"

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
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
    username   = "iac"
    public_key = data.azurerm_ssh_public_key.skylab.public_key
  }
  custom_data = base64encode(templatefile("${path.module}/userdata.yml", {
    ssh_key = data.azurerm_ssh_public_key.skylab.public_key
  }))
}

output "public_ips" {
  value = [for ip in azurerm_public_ip.pip : ip.ip_address]
}
