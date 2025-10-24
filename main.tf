data "azurerm_resource_group" "nsg" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.security_group_name
  location            = data.azurerm_resource_group.nsg.location
  resource_group_name = data.azurerm_resource_group.nsg.name
  tags                = merge(var.nsg_tags, var.regional_tags, var.global_tags)
}

#############################
#   Simple security rules   #
#############################

resource "azurerm_network_security_rule" "predefined_rules" {
  count                                      = length(var.predefined_rules)
  name                                       = lookup(var.predefined_rules[count.index], "name")
  priority                                   = lookup(var.predefined_rules[count.index], "priority", 4096 - length(var.predefined_rules) + count.index)
  direction                                  = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 0)
  access                                     = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 1)
  protocol                                   = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 2)
  source_port_ranges                         = split(",", replace(lookup(var.predefined_rules[count.index], "source_port_range", "*"), "*", "0-65535"))
  destination_port_range                     = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 4)
  description                                = element(var.rules[lookup(var.predefined_rules[count.index], "name")], 5)
  source_address_prefix                      = lookup(var.predefined_rules[count.index], "source_application_security_group_ids", null) == null && var.source_address_prefixes == null ? join(",", var.source_address_prefix) : null
  source_address_prefixes                    = lookup(var.predefined_rules[count.index], "source_application_security_group_ids", null) == null ? var.source_address_prefixes : null
  destination_address_prefix                 = lookup(var.predefined_rules[count.index], "destination_application_security_group_ids", null) == null && var.destination_address_prefixes == null ? join(",", var.destination_address_prefix) : null
  destination_address_prefixes               = lookup(var.predefined_rules[count.index], "destination_application_security_group_ids", null) == null ? var.destination_address_prefixes : null
  resource_group_name                        = data.azurerm_resource_group.nsg.name
  network_security_group_name                = azurerm_network_security_group.nsg.name
  source_application_security_group_ids      = lookup(var.predefined_rules[count.index], "source_application_security_group_ids", null)
  destination_application_security_group_ids = lookup(var.predefined_rules[count.index], "destination_application_security_group_ids", null)
}

#############################
#  Detailed security rules  #
#############################

resource "azurerm_network_security_rule" "custom_rules" {
  count                                      = length(var.custom_rules)
  name                                       = lookup(var.custom_rules[count.index], "name", "default_rule_name")
  priority                                   = lookup(var.custom_rules[count.index], "priority")
  direction                                  = lookup(var.custom_rules[count.index], "direction", "Any")
  access                                     = lookup(var.custom_rules[count.index], "access", "Allow")
  protocol                                   = title(lookup(var.custom_rules[count.index], "protocol", "*"))
  source_port_range                          = lookup(var.custom_rules[count.index], "source_port_range", "*")
  destination_port_ranges                    = split(",", replace(lookup(var.custom_rules[count.index], "destination_port_range", "*"), "*", "0-65535"))
  source_address_prefix                      = lookup(var.custom_rules[count.index], "source_application_security_group_ids", null) == null && lookup(var.custom_rules[count.index], "source_address_prefixes", null) == null ? lookup(var.custom_rules[count.index], "source_address_prefix", "*") : null
  source_address_prefixes                    = lookup(var.custom_rules[count.index], "source_application_security_group_ids", null) == null ? lookup(var.custom_rules[count.index], "source_address_prefixes", null) : null
  destination_address_prefix                 = lookup(var.custom_rules[count.index], "destination_application_security_group_ids", null) == null && lookup(var.custom_rules[count.index], "destination_address_prefixes", null) == null ? lookup(var.custom_rules[count.index], "destination_address_prefix", "*") : null
  destination_address_prefixes               = lookup(var.custom_rules[count.index], "destination_application_security_group_ids", null) == null ? lookup(var.custom_rules[count.index], "destination_address_prefixes", null) : null
  description                                = lookup(var.custom_rules[count.index], "description", "Security rule for ${lookup(var.custom_rules[count.index], "name", "default_rule_name")}")
  resource_group_name                        = data.azurerm_resource_group.nsg.name
  network_security_group_name                = azurerm_network_security_group.nsg.name
  source_application_security_group_ids      = lookup(var.custom_rules[count.index], "source_application_security_group_ids", null)
  destination_application_security_group_ids = lookup(var.custom_rules[count.index], "destination_application_security_group_ids", null)
}

#########################################
#  Default Rules (Apply to all NSGs)  #
#########################################

## Deny All
resource "azurerm_network_security_rule" "default_denyall" {
  name                        = "DenyAll"
  priority                    = "4096"
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "Deny all traffic"
  resource_group_name         = data.azurerm_resource_group.nsg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#################
#   Flow Logs   #
#################

resource "azurerm_network_watcher_flow_log" "nsg-flowlogs" {
  name                      = var.network_watcher_flow_log_name
  network_watcher_name      = var.network_watcher_name
  resource_group_name       = data.azurerm_resource_group.nsg.name
  location                  = var.network_watcher_flow_log_location
  network_security_group_id = azurerm_network_security_group.nsg.id
  storage_account_id        = var.storage_account_flowlogs_id
  enabled                   = true
  version                   = 2
  retention_policy {
    enabled = true
    days    = 365
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.diag_log_analytics_workspace_id
    workspace_region      = data.azurerm_resource_group.nsg.location
    workspace_resource_id = var.diag_log_analytics_id
    interval_in_minutes   = 10
  }

  tags = merge(var.flowlog_tags, var.regional_tags, var.global_tags)
}

module "diag" {
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics?ref=v1.1.0"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_network_security_group.nsg.id
  resource_type         = "nsg"
}
