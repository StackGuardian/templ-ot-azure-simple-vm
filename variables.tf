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

variable "vm_size" {
  description = "VM size. Must support Trusted Launch (Gen2)."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "ssh_public_key" {
  description = "SSH public key for the admin user. Password login is disabled."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "Must be an OpenSSH public key, for example ssh-ed25519 AAAA..."
  }
}

# Grouped so the StackGuardian form can show them in one "Advanced Settings" section.
variable "advanced_settings" {
  description = "Settings most deployments keep at their defaults"
  type = object({
    vnet_cidr                  = optional(string, "10.0.0.0/16")       # Address space of the VNet
    admin_username             = optional(string, "azureuser")         # Admin user on the VM
    enable_public_ip           = optional(bool, false)                 # Attach a Standard public IP to the VM
    allowed_ingress_cidrs      = optional(list(string), ["0.0.0.0/0"]) # IPv4 CIDRs allowed to reach the VM when the public IP is enabled
    allowed_ingress_ports      = optional(list(number), [22])          # TCP ports opened for allowed_ingress_cidrs when the public IP is enabled
    encryption_at_host_enabled = optional(bool, false)                 # Needs the EncryptionAtHost feature registered in the subscription
    tags                       = optional(map(string), {})             # Additional tags for all resources
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(cidrnetmask(var.advanced_settings.vnet_cidr))
    error_message = "vnet_cidr must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = alltrue([for c in var.advanced_settings.allowed_ingress_cidrs : can(cidrnetmask(c))])
    error_message = "All entries in allowed_ingress_cidrs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = alltrue([for p in var.advanced_settings.allowed_ingress_ports : p >= 1 && p <= 65535])
    error_message = "Ports must be between 1 and 65535."
  }
}
