# templatefile function with a .tftpl template file in Terraform to generate dynamic content

Lab Objective : Run templates to generate Terraform configurations to be more dynamic
- templatefile:
The templatefile function in Terraform allows you to render a template file using values from your configuration. It's useful for generating dynamic configuration files by combining template files with data from Terraform.




## illustration

Usage:
Running terraform apply will render the template.tpl file, substituting ${name} with the value provided in the templatefile function.


This example demonstrates how to use the templatefile function with a .tftpl template file in Terraform to generate dynamic content based on variables passed into the template. 

```

variable "message" {
  default = "Hello, ${name}!"
}

```


```

locals {
  name = "World"
}

output "result" {
  value = templatefile("${path.module}/example.tftpl", { name = local.name })
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


