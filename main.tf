provider "azurerm" {
  version = "~>2"
  features {}
}

resource "azurerm_resource_group" "main" {
  name = "ansible-lab"
  location = "southeastasia"
}

resource "azurerm_virtual_network" "main" {
  name = "${var.prefix}-network"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name = "internal"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "pip" {
  count = 5
  name = "${var.prefix}-pip-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  count               = 5
  name                = "${var.prefix}-nic-vm${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pip.*.id, count.index)
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  count = 5
  name = "ansible-serverlab${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s"
  admin_username = "fakhridarmawan"
  admin_password = "P@ssw0rd.12345"
  disable_password_authentication = false
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}