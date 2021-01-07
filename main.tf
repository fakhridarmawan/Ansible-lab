provider "azurerm" {
  version = "~>2"
  features {}
}

#Membaut Resource Group
resource "azurerm_resource_group" "main" {
  name = "RHCE8"
  location = "southeastasia"
  tags = {
    environment = "LAB ANSIBLE"
  }
}

#Membuat Virtual Network di dalam Cloud Azure
resource "azurerm_virtual_network" "main" {
  name = "${var.prefix}-network"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

tags = {
    environment = "LAB ANSIBLE"
  }

}

#Membuat subnetwork di dalam internal cloud azure milik kita
resource "azurerm_subnet" "internal" {
  name = "internal"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.3.0/24"]
}

# Membuat dan mengassign publik ip ke VM yang di provisioning supaya dapat di akses dari internet
resource "azurerm_public_ip" "pip" {
  count = 6
  name = "${var.prefix}-pip-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  allocation_method = "Static"

  tags = {
    environment = "LAB ANSIBLE"
  }
}

# Membuat security group untuk membuka hanya akses ssh 
resource "azurerm_network_security_group" "akses-ssh" {
    name                = "Firewall-SecurityGroups"
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.main.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        
    }

    tags = {
        environment = "LAB ANSIBLE"
    }
}


resource "azurerm_network_interface" "main" {
  count               = 6
  name                = "${var.prefix}-nic-vm${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pip.*.id, count.index)
  }
  
  tags = {
        environment = "LAB ANSIBLE"
    }
}

# Binding security group ke network interface yang sudah dibuat di atas.
resource "azurerm_network_interface_security_group_association" "bind-akses-ssh" {
    count = 6
    network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
    network_security_group_id = azurerm_network_security_group.akses-ssh.id
}

resource "azurerm_managed_disk" "main" {
 count                = 6
 name                 = "datadisk_${count.index}"
 location             = azurerm_resource_group.main.location
 resource_group_name  = azurerm_resource_group.main.name
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "4"
}

resource "azurerm_virtual_machine" "main" {
#resource "azurerm_linux_virtual_machine" "main" {
  count = 6
  name = "node${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  vm_size = "Standard_B1s"
  #computer_name = "manage-node${count.index}"
  #admin_username = "azure-administrator"
  #disable_password_authentication = true
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]

  #admin_ssh_key {
  #      username = "azure-administrator"
  #      public_key = file("~/.ssh/id_rsa.pub")
  #     }

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8"
    version   = "8.0.20191023"
  }

  storage_os_disk {
    name  = "OS_disk_${count.index}"
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  #storage_data_disk {
  #  name              = "datadisk_new_${count.index}"
  # managed_disk_type = "Standard_LRS"
  # create_option     = "Attach"
  # lun               = 0
  # disk_size_gb      = 5
  #}

  storage_data_disk {
   name            = element(azurerm_managed_disk.main.*.name, count.index)
   managed_disk_id = element(azurerm_managed_disk.main.*.id, count.index)
   create_option   = "Attach"
   lun             = 0
   disk_size_gb    = element(azurerm_managed_disk.main.*.disk_size_gb, count.index)
 }

  os_profile {
    computer_name  = "node${count.index}"
    admin_username = "automation"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
    path = "/home/automation/.ssh/authorized_keys"
    key_data = file("~/.ssh/id_rsa.pub")
  }
  }


    provisioner "file" {
   source = "initial-config.sh"
   destination = "/tmp/initial-config.sh"
   
   connection {
			host = element(azurerm_public_ip.pip.*.ip_address, count.index)
			type	= "ssh"
			user	= "automation"
      private_key = file("~/.ssh/id_rsa")
      }  
    }  

  provisioner "remote-exec" {
    inline = [
	"chmod +x /tmp/initial-config.sh",
  "sudo /tmp/initial-config.sh args"   
   ]

connection {
			host = element(azurerm_public_ip.pip.*.ip_address, count.index)
			type	= "ssh"
			user	= "automation"
      private_key = file("~/.ssh/id_rsa")
			}  
} 

#provisioner "file" {
 #  source = "setup-ansible.sh"
  # destination = "/tmp/setup-ansible.sh"
   
   #connection {
		#	host = element(azurerm_public_ip.pip.*.ip_address, count.index)
		#	type	= "ssh"
		#	user	= "azure-administrator"
     # private_key = file("~/.ssh/id_rsa")
      #}  
    #}  

#  provisioner "remote-exec" {
 #   inline = [
#	"chmod +x /tmp/setup-ansible.sh",
 # "bash /tmp/setup-ansible.sh"   
 #  ]

#connection {
			#host = element(azurerm_public_ip.pip.*.ip_address, count.index)
			#type	= "ssh"
			#user	= "azure-administrator"
      #private_key = file("~/.ssh/id_rsa")
			#}  
#} 

}

#resource "azurerm_managed_disk" "example" {
#  count = 6
#  name = "data-disk${count.index}-disk2"
#  location             = azurerm_resource_group.main.location
#  resource_group_name  = azurerm_resource_group.main.name
#  storage_account_type = "Standard_LRS"
#  create_option        = "FromImage"
#  disk_size_gb         = 4
#}




