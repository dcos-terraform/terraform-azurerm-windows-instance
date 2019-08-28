Azure DC/OS Windows Instances
===================================
This module creates typical Windows instances
_Be aware that this feature is in EXPERIMENTAL state_

EXAMPLE
-------

```hcl
locals {
  cluster_name        = "prod"
  location            = "West US"
  dcos_version        = "1.13.3"
  dcos_variant        = "open"
  dcos_instance_os    = "centos_7.6"
  dcos_winagent_os    = "windows_1809"
  vm_size             = "Standard_D2s_v3"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
}

module "winagent" {
  source = "dcos-terraform/windows-instance/azurerm"

  providers = {
    azurerm = "azurerm"
  }

  location         = "${local.location}"
  dcos_instance_os = "${local.dcos_winagent_os}"
  cluster_name     = "${local.cluster_name}"

  hostname_format = "winagt-%[1]d-%[2]s"

  subnet_id           = "${module.dcos.infrastructure.subnet_id}"
  resource_group_name = "${module.dcos.infrastructure.resource_group_name}"
  vm_size             = "${local.vm_size}"
  admin_username      = "dcosadmin"

  num = 3
}

output "winagent-ips" {
  description = "Windows IP"
  value       = "${module.winagent.public_ips}"
}

output "windows_passwords" {
  description = "Windows Password for user ${module.winagent.admin_username}"
  value       = ["${concat(module.winagent.windows_passwords)}"]
}```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| admin\_username | Windows admin user to be used | string | n/a | yes |
| cluster\_name | Name of the DC/OS cluster | string | n/a | yes |
| dcos\_instance\_os | Operating system to use. Instead of using your own image you could use a provided tested OS | string | windows_1809 | no |
| location | Azure Region | string | n/a | yes |
| num | How many instances should be created | string | n/a | yes |
| resource\_group\_name | Name of the azure resource group | string | n/a | yes |
| subnet\_id | Subnet ID | string | n/a | yes |
| vm\_size | Azure virtual machine size | string | n/a | yes |
| avset\_platform\_fault\_domain\_count | Availability set platform fault domain count, differs from location to location | string | `"3"` | no |
| custom\_data | User data to be used on these instances (cloud-init) | string | `""` | no |
| disk\_size | Disk Size in GB | string | `"120"` | no |
| disk\_type | Disk Type to Leverage | string | `"Standard_LRS"` | no |
| hostname\_format | Format the hostname inputs are index+1, region, cluster_name. Azure limits with 15 chars in total | string | `"winagt-%[1]d-%[2]s"` | no |
| image | Source image to boot from. Example, `image = { "offer" = "MicrosoftWindowsServer" "publisher" = "WindowsServer" "sku" = "Datacenter-Core-1809-with-Containers-smalldisk" "version" = "17763.615.1907121548" }`| map | `<map>` | no |
| name\_prefix | Name Prefix | string | `""` | no |
| network\_security\_group\_id | Security Group Id | string | `""` | no |
| tags | Add custom tags to all resources | map | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| admin\_username | Windows admin to be used |
| private\_ips | List of private ip addresses created by this module |
| public\_ips | List of public ip addresses created by this module |
| windows\_passwords | Returns generated or specified by user windows passwords |
