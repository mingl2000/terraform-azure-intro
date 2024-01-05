
resource "azurerm_public_ip" "lab-bastion" {
  name                = "aztf-labs-public-ip"
  resource_group_name = azurerm_resource_group.lab.name
  location            = local.region
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = local.common_tags
}


resource "azurerm_network_interface" "lab-bastion" {
  name                = "aztf-labs-nic"
  resource_group_name = azurerm_resource_group.lab.name
  location            = local.region

  ip_configuration {
    name                          = "aztf-labs-app-ipconfig"
    subnet_id                     = azurerm_subnet.lab-public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab-bastion.id
  }

  tags = local.common_tags
}


resource "azurerm_linux_virtual_machine" "lab-bastion" {
  name                  = "aztf-labs-bastion-vm"
  resource_group_name   = azurerm_resource_group.lab.name
  location              = local.region
  size                  = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.lab-bastion.id]
  admin_username        = "adminuser"
  admin_password        = "aztfVMpwd42"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello, World!' > hello.txt",  # Execute shell commands on the remote VM

    ]

    connection {
      timeout     = "1m"  # Increase timeout if needed
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.lab-bastion.public_ip_address
      user        = "adminuser"
      password    = "aztfVMpwd42"  # Use the same password specified above
    }
  }

  tags = local.common_tags
}
