# Azure Network Security Group

Azure Network Security Group Deployment

## Description

This module manages an Azure network security group (NSG).

### Versions

Terraform: 1.1.7

AzureRM Provider: 3.4.1

Validated Cloud: Government

FedRAMP Compliance Level: Mod/High

DoD Impact Compliance Level: N/A

Other Compliance Levels: N/A

## Resource List

- Network Security Group
- Default Rules e.g `deny all`
- Network Watcher Flow Log
- Diagnostic settings

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| resource_group_name | Azure Resource Group resource will be deployed in | string | N/A | yes |
| diag_log_analytics_id | ID of the Log Analytics Workspace diagnostic logs should be sent to | string | N/A | yes |
| regional_tags | Regional level tags | map(string) | {} | yes |
| global_tags | Global level tags | map(string) | {} | yes |
| storage_account_flowlogs_id | The ID of the Storage Account where flow logs are stored | string | N/A | yes |
| network_watcher_name | The name of the Network Watcher | string | N/A | yes |
| network_watcher_flow_log_name | The name of the Network Watcher Flow Log | string | N/A | yes |
| diag_log_analytics_workspace_id | LAW Workspace ID (GUID) for traffic analytics logs | string | N/A | yes |
| security_group_name | Network security group name | string | nsg | no |
| network_watcher_flow_log_location | Location (Azure Region) for the network watcher flow logs | string | usgovvirginia | no |
| location | The Azure location/region to create resources in. If not specified, uses RG location | string | "" | no |
| nsg_tags | Key/Value tags that should be added to NSG | map(string) | {} | no |
| flowlog_tags | Key/Value tags that should be added to Flow Logs | map(string) | {} | no |
| predefined_rules | Set of built-in rule such as SSH or HTTPS | list(map) | [] | no |
| custom_rules | Security rules for the network security group using this format name = [priority, direction, access, protocol, source_port_range, destination_port_range, source_address_prefix, destination_address_prefix, description] |  list(map) | [] | no |
| source_address_prefix | Source address prefix to be applied to all predefined rules | list(string) | ["*"] | no |
| source_address_prefixes | Source address prefixes to be applied to all predefined rules | list(string) | null | no |
| destination_address_prefix | Destination address prefix to be applied to all predefined rules | list(string) | ["*"] | no |
| destination_address_prefixes | Destination address prefixes to be applied to all predefined rules | list(string) | null | no |

## Outputs

| Name | Description |
|------|-------------|
| network_security_group_id | The id for the nsg resource |
| network_security_group_name | The name for the nsg resource |

## Additional Information

This Terraform module deploys a Network Security Group (NSG) in Azure and optionally attach it to the specified vnets.

This module is a complement to the [Azure Network](https://registry.terraform.io/modules/Azure/network/azurerm) module. Use the network_security_group_id from the output of this module to apply it to a subnet in the Azure Network module.
**NOTE**: We are working on adding the support for applying a NSG to a network interface directly as a future enhancement.

This module includes a a set of pre-defined rules for commonly used protocols (for example HTTP or ActiveDirectory) that can be used directly in their corresponding modules or as independent rules.

**NOTE:** `source_address_prefix` is defined differently in `predefined_rules` and `custom_rules`.
`predefined_rules` uses `var.source_address_prefix` defined in the module.`var.source_address_prefix` is of type list(string), but allowed only one element (CIDR, `*`, source IP range or Tags). For more source_address_prefixes, please use `var.source_address_prefixes`. The same for `var.destination_address_prefix` in `predefined_rules`.
`custom_rules` uses `source_address_prefix` defined in the block `custom_rules`. `source_address_prefix` is of type string (CIDR, `*`, source IP range or Tags). For more source_address_prefixes, please use `source_address_prefixes` in block `custom_rules`. The same for `destination_address_prefix` in `custom_rules`.

## Usage

```hcl
module "towerinstance-nsg" {
  source = "../../../../modules/azurerm-network-security-group"

  resource_group_name           = data.terraform_remote_state.setup.outputs.network_rg_name
  security_group_name           = "${local.resource_prefix}-tower-nsg"
  storage_account_flowlogs_id   = data.terraform_remote_state.setup.outputs.storage_account_flowlogs_id
  network_watcher_name          = data.terraform_remote_state.setup.outputs.network_watcher_name
  network_watcher_flow_log_name = "${local.resource_prefix}-tower-nfl"
  global_tags                   = var.global_tags
  regional_tags                 = var.regional_tags
  diag_log_analytics_id         = data.terraform_remote_state.core.outputs.core_la_id
  nsg_tags = {
    Function = "CICD"
    Plane    = "Management"
  }

  custom_rules = [
    {
      name                    = "SSH"
      priority                = "1000"
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      destination_port_range  = "22"
      source_address_prefixes = [var.mgmt_network_cidr]
      description             = "SSH"
    },
    {
      name                    = "HTTPS"
      priority                = "1100"
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      destination_port_range  = "443"
      source_address_prefixes = [var.mgmt_network_cidr]
      description             = "HTTPS"
    },
    {
      name                    = "DSM"
      priority                = "3100"
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      destination_port_range  = "4118"
      source_address_prefixes = [var.mgmt_network_cidr]
      description             = "Trend DSM bidirectional port for Linux VMs"
    },
    {
      name                    = "EgressAll"
      priority                = "1200"
      direction               = "Outbound"
      access                  = "Allow"
      protocol                = "*"
      destination_port_range  = "*"
      source_address_prefixes = ["0.0.0.0/0"]
      description             = "Allow Egress"
    }
  ]

  #Example with predefined rules
  predefined_rules = [
    {
      name     = "SSH"
      priority = "500"
    },
    {
      name              = "LDAP"
      source_port_range = "1024-1026"
    }
  ]
}
```
