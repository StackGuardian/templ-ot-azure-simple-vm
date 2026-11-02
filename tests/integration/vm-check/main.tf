# Helper for the integration test: reads the power state of the deployed VM.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "vm_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

data "azurerm_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
}

output "power_state" {
  value = data.azurerm_virtual_machine.this.power_state
}
