variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.name_prefix))
    error_message = "Use 2-16 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "germanywestcentral"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vm_size" {
  description = "VM size. Must support Trusted Launch (Gen2)."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "vnet_cidr" {
  description = "Address space of the VNet"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "admin_username" {
  description = "Admin user on the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for the admin user. Password login is disabled."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "Must be an OpenSSH public key, for example ssh-ed25519 AAAA..."
  }
}

variable "enable_public_ip" {
  description = "Attach a Standard public IP to the VM"
  type        = bool
  default     = false
}

variable "allowed_ingress_cidrs" {
  description = "IPv4 CIDRs allowed to reach the VM when the public IP is enabled"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_ingress_cidrs : can(cidrnetmask(c))])
    error_message = "All entries must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = alltrue([for c in var.allowed_ingress_cidrs : try(tonumber(split("/", c)[1]) >= 8, false)])
    error_message = "CIDRs broader than /8, such as 0.0.0.0/0, are not allowed."
  }
}

variable "allowed_ingress_ports" {
  description = "TCP ports opened for allowed_ingress_cidrs when the public IP is enabled"
  type        = list(number)
  default     = [22]

  validation {
    condition     = alltrue([for p in var.allowed_ingress_ports : p >= 1 && p <= 65535])
    error_message = "Ports must be between 1 and 65535."
  }
}

variable "encryption_at_host_enabled" {
  description = "Encrypt temp disk and caches on the host. Needs the EncryptionAtHost feature registered in the subscription."
  type        = bool
  default     = false
}

variable "network_watcher" {
  description = "Existing Network Watcher for VNet flow logs (one per region and subscription). Null disables flow logs."
  type = object({
    name                = string
    resource_group_name = string
  })
  default = null
}

variable "log_retention_days" {
  description = "Retention of the VNet flow logs"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 0 && var.log_retention_days <= 365
    error_message = "Flow log retention must be between 0 (keep forever) and 365 days."
  }
}
