module "nsg" {
  source              = "../../"
  resource_group_name = var.resource_group_name

  security_group_name = var.security_group_name

  predefined_rules = [
    {
      name = "HTTPS"
    },
  ]

  custom_rules               = var.custom_rules
  source_address_prefixes    = var.source_address_prefixes
  destination_address_prefix = var.destination_address_prefix
  tags                       = var.tags
}
