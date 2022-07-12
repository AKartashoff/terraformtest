#Added comment for the first automated CI/CD run! ver 2
terraform {
  backend "azurerm" {
    resource_group_name   = "gmhtest-infra"
    storage_account_name  = "gmhteststate"
    container_name        = "tstate"
    key                   = "zt+MuQDLc+cb7cDyGZx/jsh/B9nzIS5BFXmkvjIrqFyAwT9a/qHk7iqfGdEQKF8Aw8/dgd9F2cx7+AStjwpYAQ=="
  }
  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source = "hashicorp/azurerm"
      version = ">= 3.13.0"
    }
  }
}
provider "azurerm" {
  features {
      key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - Jonnychipz-RG
resource "azurerm_resource_group" "rg" {
  name     = "gmh-test"
  location = "germanywestcentral"
}
# Create our Virtual Network - gmhtest-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "gmhtestvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - gmhtest
resource "azurerm_storage_account" "gmhtest" {
  name                     = "gmhtest"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "gmhtestenv"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "gmhtestvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - gmhtest-VM01
resource "azurerm_virtual_machine" "gmhtestvm01" {
  name                  = "gmhtestvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "gmhtestvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "gmhtestvm01"
    admin_username     = "gmhadmin"
    admin_password     = "Password123$"
  }
  os_profile_windows_config {
  }

}