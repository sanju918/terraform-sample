# Variable Section
# variable "subscription_id" { }
# variable "client_id" {}
# variable "client_secret" {}
# variable "tenant_id" {}

variable "web_server_location" {}
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_address_prefix" {}
variable "web_server_name" {}
variable "environment" {}

# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version         = "1.28.0"
  #client_id       = "${var.client_id}"
  #client_secret   = "${var.client_secret}"
  #tenant_id       = "${var.tenant_id}"
  #subscription_id = "${var.subscription_id}"
}

# Create a resource group
resource "azurerm_resource_group" "web_server_rg" { 
  name     = "${var.web_server_rg}"
  location = "${var.web_server_location}"
}

# Create a vnet
resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet-v2"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}

#Create a subnet
resource "azurerm_subnet" "web_server_subnet"{
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix       = "${var.web_server_address_prefix}"
}
 resource "azurerm_public_ip" "web_server_publicip"{
   name                           = "${var.resource_prefix}-pubip"
   location                       = "${var.web_server_location}"
   resource_group_name            = "${azurerm_resource_group.web_server_rg.name}"
   allocation_method              = "Dynamic"
 }
resource "azurerm_network_interface" "web_server_nic"{
  name                      = "${var.web_server_name}-nic"
  location                  = "${var.web_server_location}"
  resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  network_security_group_id = "${azurerm_network_security_group.web_server_nsg.id}"

  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = "${azurerm_subnet.web_server_subnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.web_server_publicip.id}"

    # public ip allocation - uncomment the following line of code
    # private_ip_address_allocation = "dynamic"
    
    # conditional public ip allocation - uncomment the folloiwng line of code
    private_ip_address_allocation = "${var.environment == "production" ? "Static" : "Dynamic"}"
  }
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name = "${var.resource_prefix}-nsg"
  location = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name = "RDP Inbound"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "TCP"
  source_address_prefix = "*"
  source_port_range = "*"
  destination_address_prefix = "*"
  destination_port_range = "3389"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}"
}

# Creating the Virutal Machine

resource "azurerm_virtual_machine" "web_server" {
  name                  = "${var.web_server_name}"
  location              = "${var.web_server_location}"
  resource_group_name   = "${azurerm_resource_group.web_server_rg.name}"
  network_interface_ids = ["${azurerm_network_interface.web_server_nic.id}"]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
     name               = "${var.web_server_name}-os"
     caching            = "ReadWrite"
     create_option      = "FromImage"
     managed_disk_type  = "Standard_LRS"
  }

  os_profile {
    computer_name   = "${var.web_server_name}"
    admin_username  = "cenzer2"
    admin_password  = "P@ssw0rd@1234"
  }

  os_profile_windows_config {}
}

#resource "azurerm_storage_account" "strgacc" {
 # name                      = "${var.resource_prefix}strgacc"
 # location                  = "${var.web_server_location}"
 # resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
 # account_tier              = "Standard"
 # account_replication_type  = "GRS"
 # account_kind              = "StorageV2"
 # access_tier               = "Hot"
#}