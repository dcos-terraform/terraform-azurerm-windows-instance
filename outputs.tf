output "admin_username" {
  description = "SSH User"
  value       = "${local.admin_username}"
}

output "windows_passwords" {
  description = "Windows admin password"
  value       = ["${random_password.password.*.result}"]
}

output "private_ips" {
  description = "List of private ip addresses created by this module"
  value       = ["${azurerm_network_interface.instance_nic.*.private_ip_address}"]
}

output "public_ips" {
  description = "List of public ip addresses created by this module"
  value       = ["${azurerm_public_ip.instance_public_ip.*.fqdn}"]
}
