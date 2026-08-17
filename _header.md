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

