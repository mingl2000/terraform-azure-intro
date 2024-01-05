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

Here is the dynamic config output that will be returned


![templatefile](https://github.com/raviag09/terraform-azure-intro/assets/131940031/f95b9ce1-ba11-4af4-a32b-92f2d65ae324)


Exit the SSH session on the virtual machine.


