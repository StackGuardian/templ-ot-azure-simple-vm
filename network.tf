resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "vm" {
  name                            = "vm"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [cidrsubnet(var.vnet_cidr, 8, 0)]
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "vm" {
  name                = "${var.name_prefix}-vm-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "public" {
  for_each = local.public_ingress

  name                        = "allow-${each.value.port}-${each.value.priority}"
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = each.value.cidr
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = tostring(each.value.port)
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm.name
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# VNet flow logs (optional, needs an existing Network Watcher)
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "flow_logs" {
  #checkov:skip=CKV_AZURE_59:Network Watcher writes as a trusted Microsoft service, firewall denies everything else
  #checkov:skip=CKV2_AZURE_33:Private endpoint is out of scope for the demo, firewall denies public access
  #checkov:skip=CKV_AZURE_206:LRS is enough for demo flow logs
  #checkov:skip=CKV_AZURE_33:Queue service is not used
  #checkov:skip=CKV2_AZURE_1:Encrypted with Microsoft-managed keys, customer-managed keys are out of scope for the demo
  #checkov:skip=CKV2_AZURE_41:SAS tokens are not used
  #checkov:skip=CKV2_AZURE_40:The azurerm provider needs shared key access to manage the account
  count = var.network_watcher == null ? 0 : 1

  name                            = "${substr(replace(var.name_prefix, "-", ""), 0, 10)}flow${random_string.suffix.result}"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_network_watcher_flow_log" "this" {
  count = var.network_watcher == null ? 0 : 1

  name                 = "${var.name_prefix}-vnet-flow-log"
  network_watcher_name = var.network_watcher.name
  resource_group_name  = var.network_watcher.resource_group_name
  target_resource_id   = azurerm_virtual_network.this.id
  storage_account_id   = azurerm_storage_account.flow_logs[0].id
  enabled              = true
  version              = 2

  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }

  tags = local.tags
}
