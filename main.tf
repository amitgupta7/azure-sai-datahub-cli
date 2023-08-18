
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id            = var.az_subscription_id
  skip_provider_registration = true
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.az_name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = var.az_resource_group
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.az_name_prefix}_pod-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.az_resource_group
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "pod_sg" {
  name                = "${var.az_name_prefix}_pods-sg"
  location            = var.region
  resource_group_name = var.az_resource_group

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pod_ip" {
  name                = "${var.az_name_prefix}_jumpbox_ip"
  location            = var.region
  resource_group_name = var.az_resource_group
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.az_name_prefix}-jumpbox"
}

resource "azurerm_network_interface" "pod_nic" {
  name                = "${var.az_name_prefix}_jumpbox_nic"
  location            = var.region
  resource_group_name = var.az_resource_group
  ip_configuration {
    name                          = "${var.az_name_prefix}_jumpbox_ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.21"
    public_ip_address_id          = azurerm_public_ip.pod_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg" {
  network_interface_id      = azurerm_network_interface.pod_nic.id
  network_security_group_id = azurerm_network_security_group.pod_sg.id
}

resource "azurerm_linux_virtual_machine" "jumpbox-vm" {
  name                  = "${var.az_name_prefix}-jumpbox-vm"
  network_interface_ids = [azurerm_network_interface.pod_nic.id]
  //variables
  location            = var.region
  resource_group_name = var.az_resource_group
  size                = var.vm_size
  os_disk {
    name                 = "${var.az_name_prefix}-os-disk"
    disk_size_gb         = var.os_disk_size_in_gb
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }
  admin_username                  = var.azuser
  admin_password                  = var.azpwd
  disable_password_authentication = false

}

resource "null_resource" "install_dependencies" {
  triggers = {
    build_number = "build-01-01"
  }
  
  depends_on = [azurerm_linux_virtual_machine.jumpbox-vm]
  connection {
    type     = "ssh"
    user     = var.azuser
    password = var.azpwd
    host     = azurerm_public_ip.pod_ip.fqdn
  }
  provisioner "file" {
    source = "install_dependencies.sh"
    destination = "/home/${var.azuser}/install_dependencies.sh"
  }

  provisioner "file" {
    source = "update-columns.csv"
    destination = "/home/${var.azuser}/update-columns.csv"
  }

  provisioner "file" {
    source = "csv-enricher.dhub.yaml"
    destination = "/home/${var.azuser}/csv-enricher.dhub.yaml"
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sh /home/${var.azuser}/install_dependencies.sh -k ${var.X_API_Key} -s ${var.X_API_Secret} -t ${var.X_TIDENT} -h ${var.datahub_host_url}"
     ]
  }
}

output "ssh_credentials" {
  value = "ssh ${var.azuser}@${azurerm_public_ip.pod_ip.fqdn} \nwith password: ${var.azpwd}"
}