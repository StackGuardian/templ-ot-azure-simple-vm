output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "vm_name" {
  description = "Name of the VM"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_id" {
  description = "ID of the VM"
  value       = azurerm_linux_virtual_machine.this.id
}

output "private_ip" {
  description = "Private IP of the VM"
  value       = azurerm_linux_virtual_machine.this.private_ip_address
}

output "public_ip" {
  description = "Public IP of the VM, null if disabled"
  value       = one(azurerm_public_ip.this[*].ip_address)
}

output "ssh_command" {
  description = "SSH command, null unless the public IP is enabled"
  value       = var.enable_public_ip ? "ssh ${var.admin_username}@${one(azurerm_public_ip.this[*].ip_address)}" : null
}
