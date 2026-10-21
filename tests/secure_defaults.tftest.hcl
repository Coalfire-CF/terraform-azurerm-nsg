# Offline checks for the secure defaults, the input guards and tag merging.
# The provider is mocked, so no Azure credentials are needed: run
# `terraform init -backend=false` then `terraform test`.
#
# Keep every plan run above the single apply run, which must stay last.

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      name     = "test-rg"
      location = "usgovvirginia"
    }
  }

  mock_data "azurerm_monitor_diagnostic_categories" {
    defaults = {
      log_category_groups = ["allLogs"]
      log_category_types  = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
      metrics             = []
    }
  }
}

variables {
  resource_group_name   = "test-rg"
  security_group_name   = "test-nsg"
  diag_log_analytics_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-law"
}

run "defaults_create_only_deny_all" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_rule.predefined_rules) == 0 && length(azurerm_network_security_rule.custom_rules) == 0
    error_message = "With default inputs the module must create no allow rules."
  }

  assert {
    condition     = azurerm_network_security_rule.default_denyall.priority == 4096 && azurerm_network_security_rule.default_denyall.access == "Deny" && azurerm_network_security_rule.default_denyall.direction == "Inbound" && azurerm_network_security_rule.default_denyall.source_address_prefix == "*"
    error_message = "DenyAll must be an Inbound Deny from * at priority 4096."
  }
}

run "predefined_source_defaults_to_virtual_network" {
  command = plan

  variables {
    predefined_rules = [{ name = "SSH", priority = 100 }]
  }

  assert {
    condition     = azurerm_network_security_rule.predefined_rules["SSH"].source_address_prefix == "VirtualNetwork"
    error_message = "A predefined rule with no source must default to VirtualNetwork, not *."
  }

  assert {
    condition     = azurerm_network_security_rule.predefined_rules["SSH"].protocol == "Tcp" && azurerm_network_security_rule.predefined_rules["SSH"].destination_port_ranges == toset(["22"])
    error_message = "SSH must be Tcp on port 22."
  }
}

run "predefined_multi_port_rule_splits" {
  command = plan

  variables {
    predefined_rules = [{ name = "WMIfromBurp", priority = 100, source_address_prefixes = ["10.0.0.0/24", "10.0.1.0/24"] }]
  }

  assert {
    condition     = azurerm_network_security_rule.predefined_rules["WMIfromBurp"].destination_port_ranges == toset(["445", "139"])
    error_message = "WMIfromBurp must become two destination ports."
  }

  assert {
    condition     = azurerm_network_security_rule.predefined_rules["WMIfromBurp"].source_address_prefixes == toset(["10.0.0.0/24", "10.0.1.0/24"]) && azurerm_network_security_rule.predefined_rules["WMIfromBurp"].source_address_prefix == null
    error_message = "Two sources must use source_address_prefixes."
  }
}

run "predefined_management_port_from_wildcard_rejected" {
  command = plan

  variables {
    source_address_prefixes = ["*"]
    predefined_rules        = [{ name = "TowerWindows", priority = 100 }]
  }

  expect_failures = [azurerm_network_security_rule.predefined_rules]
}

run "predefined_management_port_from_internet_rejected" {
  command = plan

  variables {
    predefined_rules = [{ name = "RDP", priority = 100, source_address_prefixes = ["Internet"] }]
  }

  expect_failures = [azurerm_network_security_rule.predefined_rules]
}

run "predefined_non_management_port_from_wildcard_allowed" {
  command = plan

  variables {
    source_address_prefixes = ["*"]
    predefined_rules        = [{ name = "HTTPS", priority = 100 }]
  }

  assert {
    condition     = azurerm_network_security_rule.predefined_rules["HTTPS"].source_address_prefix == "*"
    error_message = "R10 covers management ports only; HTTPS from * must plan."
  }
}

run "predefined_unknown_name_rejected" {
  command = plan

  variables {
    predefined_rules = [{ name = "Telnet", priority = 100 }]
  }

  expect_failures = [var.predefined_rules]
}

run "custom_rule_normalised" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "AppPorts"
      priority               = 100
      direction              = "Inbound"
      protocol               = "tcp"
      destination_port_range = "8443, 9000-9100"
      source_address_prefix  = "10.0.0.0/24"
    }]
  }

  assert {
    condition     = azurerm_network_security_rule.custom_rules["AppPorts"].protocol == "Tcp"
    error_message = "A lower-case protocol must be normalised to Tcp."
  }

  assert {
    condition     = azurerm_network_security_rule.custom_rules["AppPorts"].destination_port_ranges == toset(["8443", "9000-9100"])
    error_message = "A comma-separated destination_port_range must become destination_port_ranges."
  }

  assert {
    condition     = azurerm_network_security_rule.custom_rules["AppPorts"].destination_address_prefix == "*" && azurerm_network_security_rule.custom_rules["AppPorts"].access == "Allow"
    error_message = "Destination must default to * and access to Allow."
  }
}

run "custom_management_port_from_wildcard_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "Wide"
      priority               = 100
      direction              = "Inbound"
      destination_port_range = "3000-4000"
      source_address_prefix  = "*"
    }]
  }

  expect_failures = [azurerm_network_security_rule.custom_rules]
}

run "custom_all_ports_from_cidr_zero_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                    = "Any"
      priority                = 100
      direction               = "Inbound"
      destination_port_range  = "*"
      source_address_prefixes = ["10.0.0.0/8", "0.0.0.0/0"]
    }]
  }

  expect_failures = [azurerm_network_security_rule.custom_rules]
}

run "custom_management_port_from_ipv6_any_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "SshV6"
      priority               = 100
      direction              = "Inbound"
      destination_port_range = "22"
      source_address_prefix  = "0::/0"
    }]
  }

  expect_failures = [azurerm_network_security_rule.custom_rules]
}

run "predefined_empty_source_list_rejected" {
  command = plan

  variables {
    predefined_rules = [{ name = "RDP", priority = 100, source_address_prefixes = [] }]
  }

  expect_failures = [var.predefined_rules]
}

run "custom_empty_source_list_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                    = "Empty"
      priority                = 100
      direction               = "Inbound"
      destination_port_range  = "443"
      source_address_prefixes = []
    }]
  }

  expect_failures = [var.custom_rules]
}

run "custom_deny_from_wildcard_allowed" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "DenySSH"
      priority               = 100
      direction              = "Inbound"
      access                 = "Deny"
      destination_port_range = "22"
      source_address_prefix  = "Internet"
    }]
  }

  assert {
    condition     = azurerm_network_security_rule.custom_rules["DenySSH"].access == "Deny"
    error_message = "A Deny rule from Internet on a management port must plan."
  }
}

run "custom_invalid_direction_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "Bad"
      priority               = 100
      direction              = "Any"
      destination_port_range = "443"
      source_address_prefix  = "10.0.0.0/24"
    }]
  }

  expect_failures = [var.custom_rules]
}

run "custom_missing_source_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "NoSource"
      priority               = 100
      direction              = "Inbound"
      destination_port_range = "443"
    }]
  }

  expect_failures = [var.custom_rules]
}

run "custom_priority_4096_rejected" {
  command = plan

  variables {
    custom_rules = [{
      name                   = "Late"
      priority               = 4096
      direction              = "Inbound"
      destination_port_range = "443"
      source_address_prefix  = "10.0.0.0/24"
    }]
  }

  expect_failures = [var.custom_rules]
}

run "duplicate_priority_across_lists_rejected" {
  command = plan

  variables {
    predefined_rules = [{ name = "HTTPS", priority = 100 }]
    custom_rules = [{
      name                   = "App"
      priority               = 100
      direction              = "Inbound"
      destination_port_range = "8443"
      source_address_prefix  = "10.0.0.0/24"
    }]
  }

  expect_failures = [azurerm_network_security_group.nsg]
}

run "tags_are_merged" {
  command = plan

  variables {
    tags          = { Function = "Networking" }
    regional_tags = { Region = "usgovvirginia" }
    global_tags   = { Owner = "platform" }
  }

  assert {
    condition     = azurerm_network_security_group.nsg.tags == tomap({ Function = "Networking", Region = "usgovvirginia", Owner = "platform" })
    error_message = "The NSG must carry tags merged with regional_tags and global_tags."
  }
}

# Smoke run: the apply completes with diagnostics v3.0.0 under the mock. The
# override gives the NSG a well-formed id because the provider parses
# resource_id in the diagnostics module's categories data source.
run "diagnostics_module_applies" {
  command = apply

  override_resource {
    target = azurerm_network_security_group.nsg
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityGroups/test-nsg"
    }
  }

  assert {
    condition     = output.network_security_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkSecurityGroups/test-nsg"
    error_message = "The apply must complete with the overridden NSG id."
  }
}
