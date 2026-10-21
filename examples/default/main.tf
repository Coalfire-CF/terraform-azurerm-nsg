terraform {
  required_version = ">= 1.16.6, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}

provider "azurerm" {
  features {}
  environment                     = "usgovernment"
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Network", "Microsoft.Insights"]
}

module "nsg" {
  source = "../.."

  resource_group_name   = var.resource_group_name
  security_group_name   = var.security_group_name
  diag_log_analytics_id = var.diag_log_analytics_id

  predefined_rules = [
    { name = "HTTPS", priority = 200 },
  ]

  custom_rules = [
    {
      name                    = "SSH"
      priority                = 100
      direction               = "Inbound"
      protocol                = "Tcp"
      destination_port_range  = "22"
      source_address_prefixes = var.management_cidrs
      description             = "SSH from the management network"
    },
  ]

  tags = var.tags
}
