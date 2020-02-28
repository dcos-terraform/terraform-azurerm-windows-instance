/**
 * Azure DC/OS Windows Instances
 * ===================================
 * This module creates typical Windows instances.
 * _Beaware that this feature is in EXPERIMENTAL state_
 *
 * EXAMPLE
 * -------
 *
 *```hcl
 * module "dcos-windows-instances" {
 *   source  = "dcos-terraform/windows-instance/azure"
 *   version = "~> 0.0.1"
 *
 *   subnet_id = "myid"
 *   security_group_ids = ["sg-12345678"]"
 *   admin_username = "dcosadmin"
 *   cluster_name = "dev"
 *   dcos_instance_os = "windows_1809"
 *
 *  num = "2"
 * }
 *```
 *
 * EXAMPLE 2 - With own image defintion
 * -------
 *
 *```hcl
 * module "dcos-windows-instances" {
 *   source  = "dcos-terraform/windows-instance/azure"
 *   version = "~> 0.0.1"
 *
 *   subnet_id = "myid"
 *   security_group_ids = ["sg-12345678"]"
 *   admin_username = "dcosadmin"
 *   cluster_name = "dev"
 *   image = {
 *     "offer" = "MicrosoftWindowsServer"
 *     "publisher" = "WindowsServer"
 *     "sku" = "Datacenter-Core-1809-with-Containers-smalldisk"
 *     "version" = "17763.615.1907121548"
 *   }
 *
 *   num = "2"
 * }
 *```
 */

provider "azurerm" {}

module "dcos-tested-oses" {
  source  = "dcos-terraform/tested-oses/azurerm"
  version = "~> 0.2.0"

  providers = {
    azurerm = "azurerm"
  }

  os = "${var.dcos_instance_os}"
}

resource "random_password" "password" {
  count            = "${var.num}"
  length           = 32
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  special          = true
  override_special = "!@$%&*-_=+?"
}

locals {
  cluster_name    = "${var.name_prefix != "" ? "${var.name_prefix}-${var.cluster_name}" : var.cluster_name}"
  admin_username  = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
  image_publisher = "${length(var.image) > 0 ? lookup(var.image, "publisher", "") : module.dcos-tested-oses.azure_publisher }"
  image_sku       = "${length(var.image) > 0 ? lookup(var.image, "sku", "") : module.dcos-tested-oses.azure_sku }"
  image_version   = "${length(var.image) > 0 ? lookup(var.image, "version", "") : module.dcos-tested-oses.azure_version }"
  image_offer     = "${length(var.image) > 0 ? lookup(var.image, "offer", "") : module.dcos-tested-oses.azure_offer }"
}

# instance Node
resource "azurerm_managed_disk" "instance_managed_disk" {
  count                = "${var.num}"
  name                 = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.disk_size}"
}

# Public IP addresses for the Public Front End load Balancer
resource "azurerm_public_ip" "instance_public_ip" {
  count               = "${var.num}"
  name                = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-pub-ip"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  allocation_method   = "Static"
  domain_name_label   = "${format(var.hostname_format, (count.index + 1), local.cluster_name)}"
  tags                = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}

# Create an availability set
resource "azurerm_availability_set" "instance_av_set" {
  count                        = "${var.num == 0 ? 0 : 1}"
  name                         = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = "${var.avset_platform_fault_domain_count}"
  platform_update_domain_count = 1
  managed                      = true
}

# Instance NICs
resource "azurerm_network_interface" "instance_nic" {
  name                      = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-nic"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.network_security_group_id}"
  count                     = "${var.num}"

  ip_configuration {
    name                          = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-ipConfig"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.instance_public_ip.*.id, count.index)}"
  }

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}

resource "azurerm_virtual_machine" "windows_instance" {
  name                             = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"
  location                         = "${var.location}"
  resource_group_name              = "${var.resource_group_name}"
  network_interface_ids            = ["${element(azurerm_network_interface.instance_nic.*.id, count.index)}"]
  availability_set_id              = "${element(azurerm_availability_set.instance_av_set.*.id, 0)}"
  vm_size                          = "${var.vm_size}"
  count                            = "${var.num}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_publisher}"
    offer     = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_offer}"
    sku       = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_sku}"
    version   = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_version}"
    id        = "${lookup(var.image, "id", "")}"
  }

  storage_os_disk {
    name              = "os-disk-${format(var.hostname_format, count.index + 1, local.cluster_name)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.disk_type}"
    os_type           = "windows"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.instance_managed_disk.*.name[count.index]}"
    managed_disk_id = "${azurerm_managed_disk.instance_managed_disk.*.id[count.index]}"
    create_option   = "Attach"
    caching         = "None"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.instance_managed_disk.*.disk_size_gb[count.index]}"
  }

  os_profile {
    computer_name  = "${format(var.hostname_format, count.index + 1, substr(local.cluster_name, 0, min(5, length(local.cluster_name))))}"
    admin_username = "${local.admin_username}"
    admin_password = "${element(random_password.password.*.result, count.index)}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = false
  }

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}

resource "azurerm_virtual_machine_extension" "winrm_setup" {
  name                 = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"
  virtual_machine_id   = "${element(azurerm_virtual_machine.windows_instance.*.id, count.index)}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"
  count                = "${var.num}"
  depends_on           = ["azurerm_virtual_machine.windows_instance"]

  settings = <<SETTINGS
    {
        "commandToExecute": "winrm quickconfig -q & winrm set winrm\/config @{MaxTimeoutms=\"1800000\"} & winrm set winrm\/config\/service @{AllowUnencrypted=\"true\"} & winrm set winrm\/config\/service\/auth @{Basic=\"true\"} & powershell.exe -Command \"&{ $hostname = $(Invoke-RestMethod -Headers @{'Metadata'='true'} -URI 'http:\/\/169.254.169.254\/metadata\/instance\/compute\/name?api-version=2019-02-01&&format=text'); New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation Cert:\\LocalMachine\\My; New-Item WSMan:\\localhost\\Listener -Address * -Transport HTTPS -HostName $hostname -CertificateThumbPrint $(ls Cert:\\LocalMachine\\My).Thumbprint -Force; Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False; Set-MpPreference -DisableRealtimeMonitoring $true; Enable-PSRemoting -Force }\""
    }
SETTINGS

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}
