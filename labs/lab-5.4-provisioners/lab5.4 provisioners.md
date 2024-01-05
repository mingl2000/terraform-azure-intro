# Creating a Module

Lab Objective : Run provisioners in terraform resources
- Provisioners:
Provisioners are used in Terraform to execute scripts or actions on local or remote resources after they are created.. Used to execute scripts or commands on local or remote resources.
Examples: local-exec, remote-exec.

Use Cases:
Executing scripts on virtual machines after creation.
Configuring software or installing packages.


## Preparation

we can run the commands or scripts remotely on azure resources using the provisioners. 

The command to invoke using provisioner "remote-exec"

```
resource "azurerm_virtual_machine" "example" {
  # ...
  provisioner "remote-exec" {
    inline = [
      "echo Hello from Terraform provisioner",
      "hostname"
    ]
  }
}

````

## Lab

1. provisioner block specifies the provisioner type (remote-exec in this case).
2. inline contains a list of shell commands to execute on the created EC2 instance.
3. connection block defines the connection details required for remote execution (SSH in this example).

#### Provisioner Types:
Remote-Exec: Executes commands on a remote resource (SSH into an instance and run commands).
Local-Exec: Executes commands on the machine running Terraform.
File: Uploads or downloads files to or from a remote resource.
Chef, Puppet, etc.: Integrates with configuration management tools

Ensure that your provisioner scripts or commands are idempotent and handle errors gracefully. 
Always test provisioners thoroughly to ensure they behave as expected and don't introduce unwanted side effects.

Let's setup the terraform files to create the resources on azure shell.

#### create the main file to create the resources
main.tf

```
locals {
  region = "eastus2"
  common_tags = {
    Environment = "Lab"
    Project     = "AZTF Training"
  }
}


terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 2.3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.40, < 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-course-backend"
    container_name       = "tfstate"
    key                  = "cprime.terraform.labs.tfstate"
  }
  required_version = ">= 1.0.0"
}

provider "random" {
}


provider "azurerm" {
  features {}
  # Set the following flag to avoid an Azure subscription configuration error
  skip_provider_registration = true
}


resource "azurerm_virtual_network" "lab" {
  name                = "aztf-labs-vnet"
  location            = local.region
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags

}

resource "azurerm_resource_group" "lab" {
  name     = "aztf-labs-rg"
  location = local.region
  tags     = local.common_tags
}

resource "azurerm_subnet" "lab-public" {
  name                 = "aztf-labs-subnet-public"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "lab-private" {
  name                 = "aztf-labs-subnet-private"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "lab-public" {
  name                = "aztf-labs-public-sg"
  location            = local.region
  resource_group_name = azurerm_resource_group.lab.name

security_rule {
    name                       = "SSH-Access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefixes = azurerm_subnet.lab-public.address_prefixes

}
}


resource "azurerm_subnet_network_security_group_association" "lab-public" {
  subnet_id                 = azurerm_subnet.lab-public.id
  network_security_group_id = azurerm_network_security_group.lab-public.id
}

```

#### create the vm-provisioner file

vm.tf
```

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

```

#### Running Terraform:
After adding provisioners to your Terraform configuration, run terraform init to initialize the configuration.
Execute terraform plan to review changes and terraform apply to create resources and apply provisioners.



Run terraform apply (remember to confirm yes to the changes):
```
terraform apply
```

When it finishes, try the ssh command again.  (You might need to wait a minute or two.)

This time it should prompt you for a password.  Enter the password that was configured in the vm.tf file.

*You may also be prompted to confirm that you want to connect. Enter "yes".*

Confirm you can ssh into the machine.

![cs-vm-ssh](https://github.com/raviag09/terraform-azure-intro/assets/131940031/aa0c8707-28f2-459c-b26a-a47f3971d5fb)


Ensure that text file created using provisioners is present on the virtual machine

![provisioner-hello](https://github.com/raviag09/terraform-azure-intro/assets/131940031/3a881276-5391-465e-a7a9-165424280422)


Exit the SSH session on the virtual machine.


