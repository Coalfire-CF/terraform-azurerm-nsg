![Coalfire](coalfire_logo.png)

# terraform-azurerm-nsg

This module creates a Network Security Group (NSG) with predefined and custom rules, a final DenyAll
rule, and diagnostic settings. It is used in the [Coalfire-Azure-RAMPpak](https://github.com/Coalfire-CF/Coalfire-Azure-RAMPpak) FedRAMP framework.

Learn more at [Coalfire OpenSource](https://coalfire.com/opensource).

## Dependencies

- An existing resource group. The NSG takes its location from it.
- A Log Analytics workspace for diagnostic logs.

## Resource List

- Network Security Group
- Predefined rules, picked by name from the catalog in `rules.tf`
- Custom rules
- DenyAll inbound rule at priority 4096
- Diagnostic settings, through [terraform-azurerm-diagnostics](https://github.com/Coalfire-CF/terraform-azurerm-diagnostics)

## Secure defaults

- With no rule inputs the NSG has only the DenyAll inbound rule.
- Predefined rules take their source from `source_address_prefixes`, which defaults to `VirtualNetwork`, not `*`.
- A rule that allows port 22, 3389, 5985 or 5986 from `*`, `Any`, `Internet`, or any `/0` prefix such as `0.0.0.0/0` or `::/0` fails at plan time.
- Custom rules must name a source and a destination port. There is no wildcard default for either.
- Rule names and priorities must be unique. Priorities run from 100 to 4095.

## Flow logs

This module does not create flow logs. Azure no longer allows new NSG flow logs. Use VNet flow logs
in [terraform-azurerm-vnet](https://github.com/Coalfire-CF/terraform-azurerm-vnet) instead.

## Predefined and custom rules

A predefined rule needs a `name` from the catalog and a `priority`. It may override the source or
destination for that rule. One address entry uses the singular Azure argument and may be a service
tag. Two or more entries must be CIDRs or IPs.

A custom rule takes `destination_port_range` as a port, a range, a comma-separated list, or `*`. It
takes exactly one of `source_address_prefix`, `source_address_prefixes` or
`source_application_security_group_ids`.

Attach the NSG to subnets with the `nsg_ids` input of terraform-azurerm-vnet.

## Usage

```hcl
module "app_nsg" {
  source = "git::https://github.com/Coalfire-CF/terraform-azurerm-nsg?ref=vX.Y.Z"

  resource_group_name   = var.network_rg_name
  security_group_name   = "app-nsg"
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

  tags          = var.tags
  regional_tags = var.regional_tags
  global_tags   = var.global_tags
}
```

See `examples/default` for a complete root.
