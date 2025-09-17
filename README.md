![Coalfire](coalfire_logo.png)

# terraform-azurerm-nsg

This module is used in the [Coalfire-Azure-RAMPpak](https://github.com/Coalfire-CF/Coalfire-Azure-RAMPpak) FedRAMP Framework. It will create a Network Security Group (NSG).

Learn more at [Coalfire OpenSource](https://coalfire.com/opensource).

## Dependencies

- Security Core
- Region Setup

## Resource List

- Network Security Group
- Default Rules e.g `deny all`
- Network Watcher Flow Log
- Diagnostic settings

## Additional Information

This Terraform module deploys a Network Security Group (NSG) in Azure and optionally attach it to the specified VNets.

This module is a complement to the [Azure Network](https://registry.terraform.io/modules/Azure/network/azurerm) module. Use the network_security_group_id from the output of this module to apply it to a subnet in the Azure Network module.
**NOTE**: We are working on adding the support for applying a NSG to a network interface directly as a future enhancement.

This module includes a a set of pre-defined rules for commonly used protocols (for example HTTP or ActiveDirectory) that can be used directly in their corresponding modules or as independent rules.

**NOTE:** `source_address_prefix` is defined differently in `predefined_rules` and `custom_rules`.
`predefined_rules` uses `var.source_address_prefix` defined in the module.`var.source_address_prefix` is of type list(string), but allowed only one element (CIDR, `*`, source IP range or Tags). For more source_address_prefixes, please use `var.source_address_prefixes`. The same for `var.destination_address_prefix` in `predefined_rules`.
`custom_rules` uses `source_address_prefix` defined in the block `custom_rules`. `source_address_prefix` is of type string (CIDR, `*`, source IP range or Tags). For more source_address_prefixes, please use `source_address_prefixes` in block `custom_rules`. The same for `destination_address_prefix` in `custom_rules`.

## Deployment Steps

This module can be called as outlined below.

- Change directories to the `bastion` directory.
- From the `/terraform/prod/us-va/mgmt/bastion` directory run `terraform init`.
- Run `terraform plan` to review the resources being created.
- If everything looks correct in the plan output, run `terraform apply`.

## Usage

```hcl
provider "azurerm" {
  features {}
}

module "win_bastion_nsg" {
  source = "github.com/Coalfire-CF/terraform-azurerm-nsg"

  location                          = var.location
  resource_group_name               = data.terraform_remote_state.setup.outputs.network_rg_name
  security_group_name               = "${local.vm_name_prefix}-winbastion"
  storage_account_flowlogs_id       = data.terraform_remote_state.setup.outputs.storage_account_flowlogs_id
  network_watcher_name              = data.terraform_remote_state.setup.outputs.network_watcher_name
  network_watcher_flow_log_name     = "${data.terraform_remote_state.setup.outputs.network_watcher_name}-windowsbastionflowlogs"
  network_watcher_flow_log_location = var.location
  diag_log_analytics_id             = data.terraform_remote_state.core.outputs.core_la_id
  diag_log_analytics_workspace_id   = data.terraform_remote_state.core.outputs.core_la_workspace_id

  regional_tags = var.regional_tags
  global_tags   = var.global_tags

  custom_rules = [
    {
      name                    = "RDP"
      priority                = "100"
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      destination_port_range  = "3389"
      source_address_prefixes = var.cidrs_for_remote_access
      description             = "RDP"
    }
  ]
}

resource "azurerm_subnet_network_security_group_association" "win_bastion_nsg_association" {
  subnet_id                 = data.terraform_remote_state.usgv_mgmt_vnet.outputs.usgv_mgmt_vnet_subnet_ids["${local.resource_prefix}-bastion-sn-1"]
  network_security_group_id = module.win_bastion_nsg.network_security_group_id
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_diag"></a> [diag](#module\_diag) | git::https://github.com/Coalfire-CF/terraform-azurerm-diagnostics | v1.0.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.custom_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.default_denyall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.predefined_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_watcher_flow_log.nsg-flowlogs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_resource_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_rules"></a> [custom\_rules](#input\_custom\_rules) | Security rules for the network security group using this format name = [priority, direction, access, protocol, source\_port\_range, destination\_port\_range, source\_address\_prefix, destination\_address\_prefix, description] | `any` | `[]` | no |
| <a name="input_destination_address_prefix"></a> [destination\_address\_prefix](#input\_destination\_address\_prefix) | Destination address prefix to be applied to all predefined rules | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_destination_address_prefixes"></a> [destination\_address\_prefixes](#input\_destination\_address\_prefixes) | Destination address prefix to be applied to all predefined rules Example ["10.0.3.0/32","10.0.3.128/32"] | `list(string)` | `null` | no |
| <a name="input_diag_log_analytics_id"></a> [diag\_log\_analytics\_id](#input\_diag\_log\_analytics\_id) | ID of the Log Analytics Workspace diagnostic logs should be sent to | `string` | n/a | yes |
| <a name="input_diag_log_analytics_workspace_id"></a> [diag\_log\_analytics\_workspace\_id](#input\_diag\_log\_analytics\_workspace\_id) | LAW Workspace ID (GUID) for traffic analytics logs | `string` | n/a | yes |
| <a name="input_flowlog_tags"></a> [flowlog\_tags](#input\_flowlog\_tags) | Key/Value tags that should be added to Flow Logs | `map(string)` | `{}` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global level tags | `map(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location (Azure Region) for the network security group. | `string` | `""` | no |
| <a name="input_network_watcher_flow_log_location"></a> [network\_watcher\_flow\_log\_location](#input\_network\_watcher\_flow\_log\_location) | Location (Azure Region) for the network watcher flow logs. | `string` | `"usgovvirginia"` | no |
| <a name="input_network_watcher_flow_log_name"></a> [network\_watcher\_flow\_log\_name](#input\_network\_watcher\_flow\_log\_name) | The name of the Network Watcher Flow Log | `string` | n/a | yes |
| <a name="input_network_watcher_name"></a> [network\_watcher\_name](#input\_network\_watcher\_name) | The name of the Network Watcher | `string` | n/a | yes |
| <a name="input_nsg_tags"></a> [nsg\_tags](#input\_nsg\_tags) | Key/Value tags that should be added to the Network Security Group | `map(string)` | `{}` | no |
| <a name="input_predefined_rules"></a> [predefined\_rules](#input\_predefined\_rules) | Set of built-in rule such as SSH or HTTPS | `any` | `[]` | no |
| <a name="input_regional_tags"></a> [regional\_tags](#input\_regional\_tags) | Regional level tags | `map(string)` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_rules"></a> [rules](#input\_rules) | Standard set of predefined rules | `map(any)` | <pre>{<br/>  "ActiveDirectory-AllowADDSWebServices": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "9389",<br/>    "AllowADDSWebServices"<br/>  ],<br/>  "ActiveDirectory-AllowADGCReplication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "3268",<br/>    "AllowADGCReplication"<br/>  ],<br/>  "ActiveDirectory-AllowADGCReplicationSSL": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "3269",<br/>    "AllowADGCReplicationSSL"<br/>  ],<br/>  "ActiveDirectory-AllowADReplication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "*",<br/>    "*",<br/>    "389",<br/>    "AllowADReplication"<br/>  ],<br/>  "ActiveDirectory-AllowADReplicationSSL": [<br/>    "Inbound",<br/>    "Allow",<br/>    "*",<br/>    "*",<br/>    "636",<br/>    "AllowADReplicationSSL"<br/>  ],<br/>  "ActiveDirectory-AllowADReplicationTrust": [<br/>    "Inbound",<br/>    "Allow",<br/>    "*",<br/>    "*",<br/>    "445",<br/>    "AllowADReplicationTrust"<br/>  ],<br/>  "ActiveDirectory-AllowDFSGroupPolicy": [<br/>    "Inbound",<br/>    "Allow",<br/>    "UDP",<br/>    "*",<br/>    "138",<br/>    "AllowDFSGroupPolicy"<br/>  ],<br/>  "ActiveDirectory-AllowDNS": [<br/>    "Inbound",<br/>    "Allow",<br/>    "*",<br/>    "*",<br/>    "53",<br/>    "AllowDNS"<br/>  ],<br/>  "ActiveDirectory-AllowFileReplication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "5722",<br/>    "AllowFileReplication"<br/>  ],<br/>  "ActiveDirectory-AllowKerberosAuthentication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "*",<br/>    "*",<br/>    "88",<br/>    "AllowKerberosAuthentication"<br/>  ],<br/>  "ActiveDirectory-AllowNETBIOSAuthentication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "UDP",<br/>    "*",<br/>    "137",<br/>    "AllowNETBIOSAuthentication"<br/>  ],<br/>  "ActiveDirectory-AllowNETBIOSReplication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "139",<br/>    "AllowNETBIOSReplication"<br/>  ],<br/>  "ActiveDirectory-AllowPasswordChangeKerberes": [<br/>    "Inbound",<br/>    "Allow",<br/>    "*",<br/>    "*",<br/>    "464",<br/>    "AllowPasswordChangeKerberes"<br/>  ],<br/>  "ActiveDirectory-AllowRPCReplication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "135",<br/>    "AllowRPCReplication"<br/>  ],<br/>  "ActiveDirectory-AllowSMTPReplication": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "25",<br/>    "AllowSMTPReplication"<br/>  ],<br/>  "ActiveDirectory-AllowWindowsTime": [<br/>    "Inbound",<br/>    "Allow",<br/>    "UDP",<br/>    "*",<br/>    "123",<br/>    "AllowWindowsTime"<br/>  ],<br/>  "Cassandra": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "9042",<br/>    "Cassandra"<br/>  ],<br/>  "Cassandra-JMX": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "7199",<br/>    "Cassandra-JMX"<br/>  ],<br/>  "Cassandra-Thrift": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "9160",<br/>    "Cassandra-Thrift"<br/>  ],<br/>  "CouchDB": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "5984",<br/>    "CouchDB"<br/>  ],<br/>  "CouchDB-HTTPS": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "6984",<br/>    "CouchDB-HTTPS"<br/>  ],<br/>  "DNS-TCP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "53",<br/>    "DNS-TCP"<br/>  ],<br/>  "DNS-UDP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "UDP",<br/>    "*",<br/>    "53",<br/>    "DNS-UDP"<br/>  ],<br/>  "DynamicPorts": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "49152-65535",<br/>    "DynamicPorts"<br/>  ],<br/>  "ElasticSearch": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "9200-9300",<br/>    "ElasticSearch"<br/>  ],<br/>  "FTP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "21",<br/>    "FTP"<br/>  ],<br/>  "HTTP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "80",<br/>    "HTTP"<br/>  ],<br/>  "HTTPS": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "443",<br/>    "HTTPS"<br/>  ],<br/>  "IMAP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "143",<br/>    "IMAP"<br/>  ],<br/>  "IMAPS": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "993",<br/>    "IMAPS"<br/>  ],<br/>  "Kestrel": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "22133",<br/>    "Kestrel"<br/>  ],<br/>  "LDAP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "389",<br/>    "LDAP"<br/>  ],<br/>  "MSSQL": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "1433",<br/>    "MSSQL"<br/>  ],<br/>  "Memcached": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "11211",<br/>    "Memcached"<br/>  ],<br/>  "MongoDB": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "27017",<br/>    "MongoDB"<br/>  ],<br/>  "MySQL": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "3306",<br/>    "MySQL"<br/>  ],<br/>  "Neo4J": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "7474",<br/>    "Neo4J"<br/>  ],<br/>  "POP3": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "110",<br/>    "POP3"<br/>  ],<br/>  "POP3S": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "995",<br/>    "POP3S"<br/>  ],<br/>  "PostgreSQL": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "5432",<br/>    "PostgreSQL"<br/>  ],<br/>  "RDP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "3389",<br/>    "RDP"<br/>  ],<br/>  "RabbitMQ": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "5672",<br/>    "RabbitMQ"<br/>  ],<br/>  "Redis": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "6379",<br/>    "Redis"<br/>  ],<br/>  "Riak": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "8093",<br/>    "Riak"<br/>  ],<br/>  "Riak-JMX": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "8985",<br/>    "Riak-JMX"<br/>  ],<br/>  "SMTP": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "25",<br/>    "SMTP"<br/>  ],<br/>  "SMTPS": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "465",<br/>    "SMTPS"<br/>  ],<br/>  "SSH": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "22",<br/>    "SSH"<br/>  ],<br/>  "SSHfromBurp": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "22",<br/>    "SSHfromBurp"<br/>  ],<br/>  "TowerLinux": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "22",<br/>    "TowerLinux"<br/>  ],<br/>  "TowerWindows": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "5985-5986",<br/>    "TowerWindows"<br/>  ],<br/>  "WMIfromBurp": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "445,139",<br/>    "WMIfromBurp"<br/>  ],<br/>  "WinRM": [<br/>    "Inbound",<br/>    "Allow",<br/>    "TCP",<br/>    "*",<br/>    "5986",<br/>    "WinRM"<br/>  ]<br/>}</pre> | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Network security group name | `string` | `"nsg"` | no |
| <a name="input_source_address_prefix"></a> [source\_address\_prefix](#input\_source\_address\_prefix) | Source address prefix to be applied to all predefined rules | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_source_address_prefixes"></a> [source\_address\_prefixes](#input\_source\_address\_prefixes) | Source address prefix to be applied to all predefined rules | `list(string)` | `null` | no |
| <a name="input_storage_account_flowlogs_id"></a> [storage\_account\_flowlogs\_id](#input\_storage\_account\_flowlogs\_id) | The ID of the Storage Account where flow logs are stored. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_security_group_id"></a> [network\_security\_group\_id](#output\_network\_security\_group\_id) | n/a |
| <a name="output_network_security_group_name"></a> [network\_security\_group\_name](#output\_network\_security\_group\_name) | n/a |
<!-- END_TF_DOCS -->

## Contributing

[Start Here](CONTRIBUTING.md)

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit/)

## Contact Us

[Coalfire](https://coalfire.com/)

### Copyright

Copyright © 2023 Coalfire Systems Inc.