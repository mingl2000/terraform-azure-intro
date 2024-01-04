# Creating a Module

Lab Objective : Deploy Terraform Code in Azure
- spin up a Resource group, a VNET, a subnet and a Windows Server 2016 virtual machine.
- CI/CD pipeline of Gitlab is used 

## Preparation

Please ensure that the backend storage account is available for your account as it stores the state remotely: aztflabsbackendNN. NN represents the student id(studentNN)
if not available, create a storage account in Azure portal manually

## Lab


Let's setup the terraform files to create the resources on azure shell.

#### create the main file to create the resources
main.tf

```
provider "azurerm" {
  features {}
}

terraform {
   backend "azurerm" {
    resource_group_name  = "terraform-course-backend"
    storage_account_name = "aztflabsbackend24"
    container_name       = "tfstate"
    key                  = "test.terraform.tfstate" 
 }
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

```

#### create the variables file

variables.tf
```
variable "prefix" {
  description = "provide the prefix for resources"
}

variable "location" {
  description = "input the region name where the resources need to be created"
}

```

#### create the variables.tfvars file

```

prefix = "terraform"
location = "eastus"

```


### setup the gitlab to initiate the CI/CD pipeline to manage tf project

#### Create the GitLab Project with your account and Uploading the Code. account creation takes a few mins and it's free of cost.

Go to Gitlab.com, log in with your credentials, select “New Project” and “Create Blank Project”

![gitlab account](https://github.com/raviag09/terraform-azure-intro/blob/main/labs/lab-5.3-CI_CD_Gitlab_pipeline/images/create_project_gitlab.PNG)


Clone your repository to your azure machine(bash) to upload your code:

```
git clone https://gitlab.com/ravikiranag09/terraform-test.git
```

we have the repository in our machine now, we will drop the tf files created earlier:

![folderfiles](https://github.com/raviag09/terraform-azure-intro/assets/131940031/28dca301-0a52-4098-b4eb-185765283516)

Once copied, please ensure to check the files in terraform-test repository folder.

```
[ ~/clouddrive ]$ cp * /home/student24/clouddrive/terraform-test

```
once the above steps are finished then the files will reflect in the below way:

![repositoryfiles](https://github.com/raviag09/terraform-azure-intro/assets/131940031/7aa215c6-465a-47b8-ad9b-e9980512438f)


To upload the files to the repo, we’ll use the following commands:

```
git add . #add the changes to be commited
git status #displays what files to be uploaded
git commit -m "included tf code changes" #commit the changes
git push #changes will be pushed to repo
```

In the portal, ensure the files are available:

![gitlab_project_view](https://github.com/raviag09/terraform-azure-intro/assets/131940031/8e58b3be-1f7a-436a-b202-d03d7d9a784a)



setup the Gitlab Pipeline

select Build >> pipeline Editor and then start “Create new CI/CD pipeline” option

The following snippet will be the code we’ll be using to deploy Terraform through gitlab


![ymldeploy](https://github.com/raviag09/terraform-azure-intro/assets/131940031/42e8fa2f-f3ec-4894-b0a2-68f49cc4f61e)

gitlab-ci.yml file. once the below code is added to yml then save by hitting the commit stages option.

```
stages:
  - validate
  - plan
  - apply

default:
  image:
    name: hashicorp/terraform:latest
    entrypoint:
      - /usr/bin/env
      - "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

  before_script:
    - terraform init
  cache:
    key: terraform
    paths:
      - .terraform

terraform_validate:
  stage: validate
  script:
    - terraform validate

terraform_plan:
  stage: plan
  script: 
    - terraform plan -var-file="variables.tfvars" --out plan
  artifacts:
    paths:
      - plan

terraform_apply:
  stage: apply
  script:
    - terraform apply --auto-approve plan
  when: manual
  allow_failure: false
  only:
    refs:
      - main

```

Run the pipeline manually or set it auto trigger to run the pipeline stages:

the stages of the pipeline :

![pipeline](https://github.com/raviag09/terraform-azure-intro/assets/131940031/9fe7e599-f0ec-435d-9869-fb8599fb45ac)



as your un, you may encouter an error  because we haven’t set up a service principal to deploy the resources to Azure yet, and because we didn’t specify the variables needed for Azure in Gitlab:


ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_SUBSCRIPTION_ID
ARM_TENANT_ID

### Creating the Service Principal in Azure

we will run the commands on power shell to setup the AZ service principal. 

NOTE: the first time users need to authenticate in order to execute the AZ commands, power shell options. hit the url from the powershell and paste the token


Go to your Azure subscription and find your subscription id. Open a Powershell session and make sure you have AZ CLI installed on your machine, and then run the following commands:

Below command helps us to get the subscription id - 1ba9683f-8c9d-4836-a22a-df6dab9d72f0 

```
Get-AzSubscription | more                          

Name                     Id                                   TenantId                             State
----                     --                                   --------                             -----
Terraform Course Labs 24 1ba9683f-8c9d-4836-a22a-df6dab9d72f0 ffc39dc1-4df8-4fac-a312-e2cec1d1abc5 Enabled

```

Run the below commands to create the service prinicipal and get the details . If you encounter an error, then we need to enable the permissions for subscription


```

$SubscriptionId =  "1ba9683f-8c9d-4836-a22a-df6dab9d72f0"
az account set --subscription $subscriptionId
az ad sp create-for-rbac --role="Contributor" --scopes="subscriptions/$subscriptionId" --name "id-terraformtest"

```

see the screenshots in providing the permissions:

![roleschange_subscription](https://github.com/raviag09/terraform-azure-intro/assets/131940031/60ab7c1f-44a7-485f-9fa8-b07f5e648a24)


![user_Access_admin_role_assignment](https://github.com/raviag09/terraform-azure-intro/assets/131940031/7c428767-31eb-4d7c-9c5a-72db4cc487c9)

![subscription_role_assignments](https://github.com/raviag09/terraform-azure-intro/assets/131940031/09da4694-5b7b-42ea-b4d5-839dd9474a9f)



the  commands will create a service principal on your Azure Active Directory that has contributor access to the subscription you want to deploy the resources, this is more than enough to provision everything successfully.


```
$SubscriptionId =  "1ba9683f-8c9d-4836-a22a-df6dab9d72f0"

az login
az account set --subscription $subscriptionId
az ad sp create-for-rbac --role="Contributor" --scopes="subscriptions/$subscriptionId" --name "id-terraformtest"
```

The output will display for the above commands:


```
{
  "appId": "0a2bc3fb-89e3-4552-a186-4822eb097394",  # ARM_CLIENT_ID — Service Principal appID
  "displayName": "id-terraformtest",
  "password": "66Z8Q~PmW.PqWAV3zFWfwZIDsGxQHee4cSEqSdl2", #ARM_CLIENT_SECRET — Service Principal Password
  "tenant": "ffc39dc1-4df8-4fac-a312-e2cec1d1abc5"   # ARM_TENANT_ID — Tenant ID
}
```

Adding the above output Azure Variables to Gitlab

The following information will be used based on the output that we had in the previous section:

ARM_TENANT_ID — Tenant ID
ARM_CLIENT_ID — Service Principal APPID
ARM_CLIENT_SECRET — Service Principal Password 
ARM_SUBSCRIPTION_ID — Subscription ID generated from Get-AzSubscription | more 

![variables_add](https://github.com/raviag09/terraform-azure-intro/assets/131940031/9a414007-78e0-40c6-b342-bf634007af9a)


![CICD_ARM_variables_Config](https://github.com/raviag09/terraform-azure-intro/assets/131940031/1e1dfecc-6a2c-46e5-9c3d-158123d1bc69)

### pipeline is all set for run to create the resources

![runpipeline](https://github.com/raviag09/terraform-azure-intro/assets/131940031/7697b381-048e-47eb-a72d-e377b4f91deb)

All the environment is configured and ready to deploy the resources, let’s run our pipeline

once run, we can see the resources on azure portal.


Optional( Bonus):

Add the code above to the main.tf file, make the commit to repository and wait for pipeline to run:


```

resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium"
  admin_enabled       = false
}

```









