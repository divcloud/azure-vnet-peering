provider "azurerm" {
  features {}
  subscription_id = "xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" # Set 
}

# TODO: Setup Private DNS (name resolution) & Inter-spoke communication via hub
# Possible inter-spoke communication solutions (custom VM router in the host-dns-subnet, Azure Firewall, NSGs)

# Resource Group
resource "azurerm_resource_group" "network-rg" {
  name     = "network-rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "hub-vnet" {
  resource_group_name = azurerm_resource_group.network-rg.name
  location            = azurerm_resource_group.network-rg.location
  name                = "hub-vnet"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub-dns-subnet" {
  name                 = "hub-dns-subnet"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.1.0/24"] # DNS infra (centralized name resolution)
}

resource "azurerm_virtual_network" "spoke1-vnet" {
  resource_group_name = azurerm_resource_group.network-rg.name
  location            = azurerm_resource_group.network-rg.location
  name                = "spoke1-vnet"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spoke1-deployment-subnet" {
  name                 = "spoke1-deployment-subnet"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.spoke1-vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_virtual_network" "spoke2-vnet" {
  resource_group_name = azurerm_resource_group.network-rg.name
  location            = azurerm_resource_group.network-rg.location
  name                = "spoke2-vnet"
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "spoke2-deployment-subnet" {
  name                 = "spoke2-deployment-subnet"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}


// Spoke #1
resource "azurerm_virtual_network_peering" "hub-spoke1-peering" {
  virtual_network_name         = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke1-vnet.id
  resource_group_name          = azurerm_resource_group.network-rg.name
  name                         = "hub-spoke1-peering"
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke1-hub-peering" {
  virtual_network_name         = azurerm_virtual_network.spoke1-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub-vnet.id
  resource_group_name          = azurerm_resource_group.network-rg.name
  name                         = "spoke1-hub-peering"
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

# Spoke 2
resource "azurerm_virtual_network_peering" "hub-spoke2-peering" {
  virtual_network_name         = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke2-vnet.id
  resource_group_name          = azurerm_resource_group.network-rg.name
  name                         = "hub-spoke2-peering"
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke2-hub-peering" {
  virtual_network_name         = azurerm_virtual_network.spoke2-vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub-vnet.id
  resource_group_name          = azurerm_resource_group.network-rg.name
  name                         = "spoke2-hub-peering"
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

# Public IPs
resource "azurerm_public_ip" "spoke1-public-ip" {
  name                = "spoke1-public-ip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_public_ip" "spoke2-public-ip" {
  name                = "spoke2-public-ip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

# NICs (Network Interface Cards)
resource "azurerm_network_interface" "spoke1-nic" {
  name                = "spoke1-nic"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1-deployment-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke1-public-ip.id
  }
}

resource "azurerm_network_interface" "spoke2-nic" {
  name                = "spoke2-nic"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2-deployment-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke2-public-ip.id
  }
}


# Virtual machines
resource "azurerm_linux_virtual_machine" "spoke1-vm" {
  name                = "spoke1-vm"
  resource_group_name = azurerm_resource_group.network-rg.name
  location            = azurerm_resource_group.network-rg.location
  size                = "Standard_F2"
  admin_username      = "azureuser"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.spoke1-nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

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
}

resource "azurerm_linux_virtual_machine" "spoke2-vm" {
  name                = "spoke2-vm"
  resource_group_name = azurerm_resource_group.network-rg.name
  location            = azurerm_resource_group.network-rg.location
  size                = "Standard_F2"
  admin_username      = "azureuser"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.spoke2-nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

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
}
