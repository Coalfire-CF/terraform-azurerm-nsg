locals {
  # Baseline R10: no wildcard or Internet source on these ports. Any /0 prefix (for example 0::/0) also counts as a wildcard.
  management_ports = [22, 3389, 5985, 5986]
  wildcard_sources = ["*", "any", "internet", "0.0.0.0/0", "::/0"]
  protocols        = { tcp = "Tcp", udp = "Udp", icmp = "Icmp", esp = "Esp", ah = "Ah", "*" = "*" }

  predefined_rules = {
    for r in var.predefined_rules : r.name => {
      priority         = r.priority
      direction        = local.rule_catalog[r.name].direction
      access           = local.rule_catalog[r.name].access
      protocol         = local.rule_catalog[r.name].protocol
      ports            = local.rule_catalog[r.name].ports
      description      = local.rule_catalog[r.name].description
      source_asg_ids   = r.source_application_security_group_ids
      destination_asgs = r.destination_application_security_group_ids
      sources          = r.source_application_security_group_ids != null ? [] : (r.source_address_prefixes != null ? r.source_address_prefixes : var.source_address_prefixes)
      destinations     = r.destination_application_security_group_ids != null ? [] : (r.destination_address_prefixes != null ? r.destination_address_prefixes : var.destination_address_prefixes)
    }
  }

  custom_rules = {
    for r in var.custom_rules : r.name => merge(r, {
      protocol = local.protocols[lower(r.protocol)]
      ports    = [for p in split(",", r.destination_port_range) : trimspace(p)]
      sources  = r.source_address_prefixes != null ? r.source_address_prefixes : (r.source_address_prefix != null ? [r.source_address_prefix] : [])
    })
  }

  # True when an Allow rule opens a management port to a wildcard or Internet source.
  predefined_exposed = {
    for k, r in local.predefined_rules : k => r.access == "Allow" && anytrue([
      for p in local.management_ports : anytrue([
        for pr in r.ports : pr == "*" || (tonumber(split("-", pr)[0]) <= p && p <= tonumber(split("-", pr)[length(split("-", pr)) - 1]))
      ])
    ]) && anytrue([for s in r.sources : contains(local.wildcard_sources, lower(trimspace(s))) || endswith(trimspace(s), "/0")])
  }

  custom_exposed = {
    for k, r in local.custom_rules : k => r.direction == "Inbound" && r.access == "Allow" && anytrue([
      for p in local.management_ports : anytrue([
        for pr in r.ports : pr == "*" || (tonumber(split("-", pr)[0]) <= p && p <= tonumber(split("-", pr)[length(split("-", pr)) - 1]))
      ])
    ]) && anytrue([for s in r.sources : contains(local.wildcard_sources, lower(trimspace(s))) || endswith(trimspace(s), "/0")])
  }

  rule_names      = concat(keys(local.predefined_rules), keys(local.custom_rules), ["DenyAll"])
  rule_priorities = concat([for r in var.predefined_rules : r.priority], [for r in var.custom_rules : r.priority], [4096])
}

data "azurerm_resource_group" "nsg" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.security_group_name
  location            = data.azurerm_resource_group.nsg.location
  resource_group_name = data.azurerm_resource_group.nsg.name
  tags                = merge(var.tags, var.regional_tags, var.global_tags)

  lifecycle {
    precondition {
      condition     = length(distinct(local.rule_names)) == length(local.rule_names)
      error_message = "Rule names must be unique across predefined_rules and custom_rules, and DenyAll is reserved."
    }
    precondition {
      condition     = length(distinct(local.rule_priorities)) == length(local.rule_priorities)
      error_message = "Rule priorities must be unique across predefined_rules and custom_rules."
    }
  }
}

#############################
#   Simple security rules   #
#############################

resource "azurerm_network_security_rule" "predefined_rules" {
  for_each = local.predefined_rules

  name                                       = each.key
  priority                                   = each.value.priority
  direction                                  = each.value.direction
  access                                     = each.value.access
  protocol                                   = each.value.protocol
  source_port_range                          = "*"
  destination_port_ranges                    = [for p in each.value.ports : p == "*" ? "0-65535" : p]
  description                                = each.value.description
  source_address_prefix                      = length(each.value.sources) == 1 ? each.value.sources[0] : null
  source_address_prefixes                    = length(each.value.sources) > 1 ? each.value.sources : null
  source_application_security_group_ids      = each.value.source_asg_ids
  destination_address_prefix                 = length(each.value.destinations) == 1 ? each.value.destinations[0] : null
  destination_address_prefixes               = length(each.value.destinations) > 1 ? each.value.destinations : null
  destination_application_security_group_ids = each.value.destination_asgs
  resource_group_name                        = data.azurerm_resource_group.nsg.name
  network_security_group_name                = azurerm_network_security_group.nsg.name

  lifecycle {
    precondition {
      condition     = !local.predefined_exposed[each.key]
      error_message = "Predefined rule ${each.key} opens a management port (22, 3389, 5985, 5986) to *, Any, Internet or /0. Set a narrower source (baseline R10)."
    }
  }
}

#############################
#  Detailed security rules  #
#############################

resource "azurerm_network_security_rule" "custom_rules" {
  for_each = local.custom_rules

  name                                       = each.key
  priority                                   = each.value.priority
  direction                                  = each.value.direction
  access                                     = each.value.access
  protocol                                   = each.value.protocol
  source_port_range                          = each.value.source_port_range
  destination_port_ranges                    = [for p in each.value.ports : p == "*" ? "0-65535" : p]
  source_address_prefix                      = each.value.source_address_prefix
  source_address_prefixes                    = each.value.source_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  destination_address_prefix                 = each.value.destination_address_prefix == null && each.value.destination_address_prefixes == null && each.value.destination_application_security_group_ids == null ? "*" : each.value.destination_address_prefix
  destination_address_prefixes               = each.value.destination_address_prefixes
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  description                                = coalesce(each.value.description, "Security rule for ${each.key}")
  resource_group_name                        = data.azurerm_resource_group.nsg.name
  network_security_group_name                = azurerm_network_security_group.nsg.name

  lifecycle {
    precondition {
      condition     = !local.custom_exposed[each.key]
      error_message = "Custom rule ${each.key} opens a management port (22, 3389, 5985, 5986) to *, Any, Internet or /0. Set a narrower source (baseline R10)."
    }
  }
}

#########################################
#  Default Rules (Apply to all NSGs)  #
#########################################

resource "azurerm_network_security_rule" "default_denyall" {
  name                        = "DenyAll"
  priority                    = 4096
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

module "diag" {
  source                = "git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics?ref=v3.0.0"
  diag_log_analytics_id = var.diag_log_analytics_id
  resource_id           = azurerm_network_security_group.nsg.id
  resource_type         = "nsg"
}
