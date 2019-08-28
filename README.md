Azure DC/OS Windows Instances
===================================
This module creates typical Windows instances.
_Beaware that this feature is in EXPERIMENTAL state_

EXAMPLE
-------

```hcl
module "dcos-windows-instances" {
  source  = "dcos-terraform/windows-instance/azure"
  version = "~> 0.0.1"

  subnet_id = "myid"
  security_group_ids = ["sg-12345678"]"
  admin_username = "dcosadmin"
  cluster_name = "dev"
  dcos_instance_os = "windows_1809"

 num = "2"
}
```

EXAMPLE 2 - With own image defintion
-------

```hcl
module "dcos-windows-instances" {
  source  = "dcos-terraform/windows-instance/azure"
  version = "~> 0.0.1"

  subnet_id = "myid"
  security_group_ids = ["sg-12345678"]"
  admin_username = "dcosadmin"
  cluster_name = "dev"
  image = {
    "offer" = "MicrosoftWindowsServer"
    "publisher" = "WindowsServer"
    "sku" = "Datacenter-Core-1809-with-Containers-smalldisk"
    "version" = "17763.615.1907121548"
  }

  num = "2"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster\_name | Name of the DC/OS cluster | string | n/a | yes |
| location | Azure Region | string | n/a | yes |
| num | How many instances should be created | string | n/a | yes |
| resource\_group\_name | Name of the azure resource group | string | n/a | yes |
| subnet\_id | Subnet ID | string | n/a | yes |
| vm\_size | Azure virtual machine size | string | n/a | yes |
| admin\_username | SSH User | string | `"dcosadmin"` | no |
| avset\_platform\_fault\_domain\_count | Availability set platform fault domain count, differs from location to location | string | `"3"` | no |
| custom\_data | User data to be used on these instances (cloud-init) | string | `""` | no |
| dcos\_instance\_os | Operating system to use. Instead of using your own AMI you could use a provided OS. | string | `"windows_1809"` | no |
| disk\_size | Disk Size in GB | string | `"120"` | no |
| disk\_type | Disk Type to Leverage | string | `"Standard_LRS"` | no |
| hostname\_format | Format the hostname inputs are index+1, region, cluster_name | string | `"winagt-%[1]d-%[2]s"` | no |
| image | Source image to boot from | map | `<map>` | no |
| name\_prefix | Name Prefix | string | `""` | no |
| network\_security\_group\_id | Security Group Id | string | `""` | no |
| tags | Add custom tags to all resources | map | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| admin\_username | SSH User |
| private\_ips | List of private ip addresses created by this module |
| public\_ips | List of public ip addresses created by this module |
| windows\_passwords | Windows admin password |

