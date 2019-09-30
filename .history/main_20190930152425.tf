# Variable Section
variable "web_server_location" {}
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_name" {}
variable "environment" {}
variable "web_server_count" {}
variable "terraform_script_version" {}

variable "web_server_subnets" {
  type = "list"
}

variable "tags" {
  type = "map"
  default = {
    environment1 = "Production"
    environment2 = "Devlopment"
  }  
}

locals {
  web_server_name   = "${var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev" }"
  build_environment = "${var.environment == "production" ? "production" : "development"}"
}


# Configure the Azure Provider
provider "azurerm" {
  version         = ">=1.28.0"
}
# Create a resource group
resource "azurerm_resource_group" "web_server_rg" { 
  name     = "${var.web_server_rg}"
  location = "${var.web_server_location}"

  tags = "${var.tags[1]}"
}
# Create a vnet
resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet-v2"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}
# Create a subnet
resource "azurerm_subnet" "web_server_subnet"{
  name                      = "${var.resource_prefix}-${substr(var.web_server_subnets[count.index], 0, length(var.web_server_subnets[count.index]) - 3)}-subnet"
  resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix            = "${var.web_server_subnets[count.index]}"
  network_security_group_id = "${azurerm_network_security_group.web_server_nsg.id}"
  count                     = "${length(var.web_server_subnets)}"
}
# Public IP Address
 resource "azurerm_public_ip" "web_server_publicip"{
   name                           = "${var.resource_prefix}-pubip"
   location                       = "${var.web_server_location}"
   resource_group_name            = "${azurerm_resource_group.web_server_rg.name}"
   allocation_method              = "Dynamic"
}
# NSG Creation
resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.resource_prefix}-nsg"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
}
# Rule-set for NSG
resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}"
  count                       = "${var.environment == "production" ? 0:1}"
}

# Creating the Virutal Machine Scaleset
resource "azurerm_virtual_machine_scale_set" "web_server" {
  name                  = "${local.web_server_name}-scale-set"
  location              = "${var.web_server_location}"
  resource_group_name   = "${azurerm_resource_group.web_server_rg.name}"
  upgrade_policy_mode   = "manual"

  sku {
    name      = "Standard_B1s"
    tier      = "Standard"
    capacity  = "${var.web_server_count}"
  }

  storage_profile_image_reference {
    publisher           = "MicrosoftWindowsServer"
    offer               = "WindowsServer"
    sku                 = "2016-Datacenter-Server-Core-smalldisk"
    version             = "latest"
  }

  storage_profile_os_disk {
     name               = ""
     caching            = "ReadWrite"
     create_option      = "FromImage"
     managed_disk_type  = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix  = "${local.web_server_name}"
    admin_username        = "cenzer2"
    admin_password        = "P@ssw0rd@1234"
  }

  os_profile_windows_config {

  }

  network_profile {
  name        = "web_server_network_profile"
  primary     = true

    ip_configuration {
      name      = "${local.web_server_name}"
      primary   = true
      subnet_id = "${azurerm_subnet.web_server_subnet.*.id[0]}"
    }
  }
}

/*
# ^^^^^^^^^^^^^  Items not required ^^^^^^^^^^^^^ #
# Creating the Virutal Machine
resource "azurerm_virtual_machine" "web_server" {
  name                  = "${var.web_server_name}-${format("%02d", count.index)}"
  location              = "${var.web_server_location}"
  resource_group_name   = "${azurerm_resource_group.web_server_rg.name}"
  network_interface_ids = ["${azurerm_network_interface.web_server_nic.*.id[count.index]}"]
  vm_size               = "Standard_B1s"
  availability_set_id   = "${azurerm_availability_set.web_server_availability_set.id}"
  count                 = "${var.web_server_count}"

  storage_image_reference {
    publisher           = "MicrosoftWindowsServer"
    offer               = "WindowsServer"
    sku                 = "2016-Datacenter-Server-Core-smalldisk"
    version             = "latest"
  }

  storage_os_disk {
     name               = "${var.web_server_name}-${format("%02d", count.index)}-os"
     caching            = "ReadWrite"
     create_option      = "FromImage"
     managed_disk_type  = "Standard_LRS"
  }

  os_profile {
    computer_name   = "${var.web_server_name}-${format("%02d", count.index)}"
    admin_username  = "cenzer2"
    admin_password  = "P@ssw0rd@1234"
  }

  os_profile_windows_config {}
}

# Availability Set for Virtual Machine
resource "azurerm_availability_set" "web_server_availability_set" {
  name                        = "${var.web_server_name}"
  location                    = "${var.web_server_location}"
  resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"
  managed                     = true
  platform_fault_domain_count = 2
}

variable "subscription_id" { }
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "web_server_address_prefix" {}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version         = ">=1.28.0"
  /*client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
}

# Network Interface configuration
resource "azurerm_network_interface" "web_server_nic"{
  name                      = "${var.web_server_name}-${format("%02d", count.index)}-nic"
  location                  = "${var.web_server_location}"
  resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  count                     = "${var.web_server_count}"

  ip_configuration {
    name                          = "${var.web_server_name}-${format("%02d", count.index)}-ip"
    subnet_id                     = "${azurerm_subnet.web_server_subnet.*.id[count.index]}"
    public_ip_address_id          = "${azurerm_public_ip.web_server_publicip.*.id[count.index]}"

    # public ip allocation - uncomment the following line of code
    # private_ip_address_allocation = "dynamic"
    # conditional public ip allocation - uncomment the folloiwng line of code
    private_ip_address_allocation = "${var.environment == "production" ? "Static" : "Dynamic"}"
  }
}
 
# Creating a Storage Account
resource "azurerm_storage_account" "strgacc" {
 name                      = "${var.resource_prefix}strgacc"
 location                  = "${var.web_server_location}"
 resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
 account_tier              = "Standard"
 account_replication_type  = "GRS"
 account_kind              = "StorageV2"
 access_tier               = "Hot"
}
*/