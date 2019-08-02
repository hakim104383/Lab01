/* 
provider
resource group
storage account
virtual network
subnet
publi IP
network interface
virtual machine
*/

locals {
  rgname       = "hakim"
  locationName = "Southeast Asia"
}

provider "azurerm" {
  version = "1.28.0"
}

//resource group
resource "azurerm_resource_group" "rg" {
  name     = local.rgname
  location = local.locationName
}

//virtual network
resource "azurerm_virtual_network" "mainvnet" {
  name                = "hakim-vnet"
  location            = local.locationName
  resource_group_name = local.rgname
  address_space       = ["10.0.0.0/16"]
}

//subnet
resource "azurerm_subnet" "subnet1" {
  name                 = "sharedservice-subnet"
  resource_group_name  = local.rgname
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefix       = "10.0.1.0/24"
}


//storage account
resource "azurerm_storage_account" "testsa" {
  name                     = "hakimstorage"
  resource_group_name      = local.rgname
  location                 = local.locationName
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

//public IP
resource "azurerm_public_ip" "iptest" {
  name                = "hkpublicip"
  location            = local.locationName
  resource_group_name = local.rgname
  allocation_method   = "Static"
}


resource "azurerm_network_interface" "test" {
  name                = "acceptanceTestNetworkInterface1"
  location            = local.locationName
  resource_group_name = local.rgname

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.iptest.id
  }

}



resource "azurerm_virtual_machine" "vm1" {
  name                  = "terraform-vm"
  location              = local.locationName
  resource_group_name   = local.rgname
  network_interface_ids = [azurerm_network_interface.test.id]
  vm_size               = "Standard_D2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vmdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hkvm01"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
  }
  boot_diagnostics {
    enabled     = "true"
    storage_uri = join(",", azurerm_storage_account.testsa.*.primary_blob_endpoint)
  }
}