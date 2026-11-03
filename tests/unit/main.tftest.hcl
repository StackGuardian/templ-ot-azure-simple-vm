# Unit tests: plan only, providers are mocked. No cloud account, no cost.
# Run: tofu test -test-directory=tests/unit
# Test case catalog: tests/README.md

mock_provider "azurerm" {
  # Some arguments are validated as Azure resource IDs, so mocked IDs must look real.
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/networkSecurityGroups/mock-nsg"
    }
  }

  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/publicIPAddresses/mock-pip"
    }
  }

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/networkInterfaces/mock-nic"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mocksa"
    }
  }
}

variables {
  # Throwaway test key, the private key was discarded.
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx5BjE6HIv/f9JIjDM/6y459/JJ17pHQxFUaUoE9DXcKBS3AXuPUuv2Qfrlke/xImnSzfAIWAcUmjBhU1i523XrqOFYzqJM3CV4KbU8UJMiXDRx16qdAt8CacqMd4qOxjSXkkFTDElOMfh9TMChBI3VcshCuQevk9g6y54cpY+y+1ejU/hmfytubSKuXDZ2wfnqEZhQ8RBD9i6TPiQ1OcqUEUEt7WHvtlxx4c4WPkQdG+Sc/EvvglyqmIcye9FCQNDt0NUjMr2mMYyuAjj0pbpMcGoFACw98DN1Y6K3ZkahE65E2uo3b54RWifgGfgMCI2jhFs1KxM02aOLGpijddhkWjP8yRSchJvY5wVkJKzjZSlTaPA2kUiShprjZIEfW4OnNStk+UV0uDRHxTcm28EUuBEceL5qXnZt/f/fdyCJrLYrphd6OjD/oNOVMkTmE96DdzYuZCM9UNT1eyhwRIFsxks9VpCSh8dz02MBJAfRJNGd7VgSLQwiN1/WADaw9M= tofu-test-only"
}

# U-01
run "defaults_are_valid" {
  command = plan

  assert {
    condition = (
      local.tags["Environment"] == "demo" &&
      local.tags["ManagedBy"] == "opentofu" &&
      local.tags["Project"] == var.name_prefix &&
      local.tags["Repository"] != ""
    )
    error_message = "Default tags are missing or wrong."
  }
}

# U-02
run "invalid_name_prefix_is_rejected" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}

# U-03
run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      Owner = "tester"
    }
  }

  assert {
    condition     = local.tags["Owner"] == "tester" && local.tags["ManagedBy"] == "opentofu"
    error_message = "Custom tags are not merged with the default tags."
  }
}

# U-04
run "no_public_ip_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_public_ip.this) == 0 && output.public_ip == null
    error_message = "No public IP must be created by default."
  }

  assert {
    condition     = azurerm_network_interface.vm.ip_configuration[0].public_ip_address_id == null
    error_message = "The NIC must not reference a public IP by default."
  }

  assert {
    condition     = length(azurerm_network_security_rule.public) == 0
    error_message = "No inbound rules must exist by default."
  }
}

# U-05
run "password_login_is_disabled" {
  command = apply

  assert {
    condition     = azurerm_linux_virtual_machine.this.disable_password_authentication
    error_message = "Password authentication must be disabled."
  }
}

# U-06
run "trusted_launch_is_enabled" {
  command = apply

  assert {
    condition     = azurerm_linux_virtual_machine.this.secure_boot_enabled && azurerm_linux_virtual_machine.this.vtpm_enabled
    error_message = "Secure Boot and vTPM must be enabled."
  }
}

# U-07
run "vm_has_managed_identity" {
  command = apply

  assert {
    condition     = azurerm_linux_virtual_machine.this.identity[0].type == "SystemAssigned"
    error_message = "The VM must have a system-assigned managed identity."
  }
}

# U-08
run "public_ip_without_cidrs_is_rejected" {
  command = plan

  variables {
    enable_public_ip = true
  }

  expect_failures = [azurerm_linux_virtual_machine.this]
}

# U-09
run "open_cidr_is_rejected" {
  command = plan

  variables {
    enable_public_ip      = true
    allowed_ingress_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.allowed_ingress_cidrs]
}

# U-10
run "public_ingress_is_restricted" {
  command = apply

  variables {
    enable_public_ip      = true
    allowed_ingress_cidrs = ["203.0.113.0/24"]
    allowed_ingress_ports = [22]
  }

  assert {
    condition     = length(azurerm_public_ip.this) == 1 && azurerm_public_ip.this[0].sku == "Standard"
    error_message = "With enable_public_ip a Standard public IP must be created."
  }

  assert {
    condition = (
      length(azurerm_network_security_rule.public) == 1 &&
      alltrue([for r in azurerm_network_security_rule.public : r.source_address_prefix == "203.0.113.0/24" && r.destination_port_range == "22" && r.access == "Allow"])
    )
    error_message = "Inbound rules must allow only the given CIDRs and ports."
  }
}

# U-11
run "flow_logs_are_off_without_network_watcher" {
  command = apply

  assert {
    condition     = length(azurerm_network_watcher_flow_log.this) == 0
    error_message = "Flow logs must not be created without a Network Watcher."
  }
}

# U-12
run "flow_logs_with_network_watcher" {
  command = apply

  variables {
    network_watcher = {
      name                = "NetworkWatcher_germanywestcentral"
      resource_group_name = "NetworkWatcherRG"
    }
  }

  assert {
    condition = (
      length(azurerm_network_watcher_flow_log.this) == 1 &&
      azurerm_network_watcher_flow_log.this[0].target_resource_id == azurerm_virtual_network.this.id
    )
    error_message = "VNet flow logs must target the VNet."
  }

  assert {
    condition     = azurerm_storage_account.flow_logs[0].min_tls_version == "TLS1_2" && !azurerm_storage_account.flow_logs[0].allow_nested_items_to_be_public
    error_message = "The flow log storage account must enforce TLS 1.2 and block public access."
  }
}

# U-13
run "broad_cidr_is_rejected" {
  command = plan

  variables {
    enable_public_ip      = true
    allowed_ingress_cidrs = ["128.0.0.0/1"]
  }

  expect_failures = [var.allowed_ingress_cidrs]
}
