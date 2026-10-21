variable "resource_group_name" {
  description = "Name of an existing resource group. The NSG takes its location from this resource group."
  type        = string
}

variable "security_group_name" {
  description = "Network security group name."
  type        = string
  default     = "nsg"
}

variable "tags" {
  description = "Tags applied to the network security group, merged with regional_tags and global_tags."
  type        = map(string)
  default     = {}
}

variable "regional_tags" {
  description = "Regional level tags, merged into the NSG tags."
  type        = map(string)
  default     = {}
}

variable "global_tags" {
  description = "Global level tags, merged into the NSG tags."
  type        = map(string)
  default     = {}
}

variable "diag_log_analytics_id" {
  description = "Resource ID of the Log Analytics workspace that receives the NSG diagnostic logs."
  type        = string
}

variable "predefined_rules" {
  description = "Rules picked by name from the catalog in rules.tf. Each entry needs a priority from 100 to 4095, unique across predefined_rules and custom_rules. An entry may override the source or destination for that rule; otherwise source_address_prefixes and destination_address_prefixes apply. An Allow rule on port 22, 3389, 5985 or 5986 is rejected if its source is `*`, Any, Internet, or any /0 prefix such as 0.0.0.0/0 or ::/0."
  type = list(object({
    name                                       = string
    priority                                   = number
    source_address_prefixes                    = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_address_prefixes               = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.predefined_rules : contains(keys(local.rule_catalog), r.name)])
    error_message = "Every predefined_rules name must be a key of the rule catalog in rules.tf."
  }

  validation {
    condition     = length(distinct([for r in var.predefined_rules : r.name])) == length(var.predefined_rules)
    error_message = "predefined_rules names must be unique."
  }

  validation {
    condition     = alltrue([for r in var.predefined_rules : r.priority >= 100 && r.priority <= 4095 && floor(r.priority) == r.priority])
    error_message = "predefined_rules priorities must be whole numbers from 100 to 4095. 4096 is the DenyAll rule."
  }

  validation {
    condition = alltrue(flatten([for r in var.predefined_rules : [
      for l in [r.source_address_prefixes, r.source_application_security_group_ids, r.destination_address_prefixes, r.destination_application_security_group_ids] : length(l) > 0 if l != null
    ]]))
    error_message = "A per-rule source or destination list in predefined_rules must have at least one entry when it is set."
  }

  validation {
    condition     = alltrue([for r in var.predefined_rules : !(r.source_address_prefixes != null && r.source_application_security_group_ids != null)])
    error_message = "A predefined rule may set source_address_prefixes or source_application_security_group_ids, not both."
  }

  validation {
    condition     = alltrue([for r in var.predefined_rules : !(r.destination_address_prefixes != null && r.destination_application_security_group_ids != null)])
    error_message = "A predefined rule may set destination_address_prefixes or destination_application_security_group_ids, not both."
  }
}

variable "source_address_prefixes" {
  description = "Source for predefined rules that set no source of their own. One entry may be a CIDR, IP or service tag. Two or more entries must be CIDRs or IPs. Setting `*` or Internet opens the selected ports to every address; it is rejected for management ports (22, 3389, 5985, 5986)."
  type        = list(string)
  default     = ["VirtualNetwork"]

  validation {
    condition     = length(var.source_address_prefixes) > 0
    error_message = "source_address_prefixes must have at least one entry."
  }
}

variable "destination_address_prefixes" {
  description = "Destination for predefined rules that set no destination of their own. One entry may be a CIDR, IP, service tag or `*`. Two or more entries must be CIDRs or IPs."
  type        = list(string)
  default     = ["*"]

  validation {
    condition     = length(var.destination_address_prefixes) > 0
    error_message = "destination_address_prefixes must have at least one entry."
  }
}

variable "custom_rules" {
  description = "Custom rules. Each needs name, priority (100 to 4095, unique across both rule lists), direction (Inbound or Outbound), destination_port_range (a port, a range, a comma-separated list, or `*`), and exactly one of source_address_prefix, source_address_prefixes or source_application_security_group_ids. access defaults to Allow, protocol to `*`, source_port_range to `*`, and the destination to `*`. An Inbound Allow rule on port 22, 3389, 5985 or 5986 is rejected if its source is `*`, Any, Internet, or any /0 prefix such as 0.0.0.0/0 or ::/0."
  type = list(object({
    name                                       = string
    priority                                   = number
    direction                                  = string
    access                                     = optional(string, "Allow")
    protocol                                   = optional(string, "*")
    source_port_range                          = optional(string, "*")
    destination_port_range                     = string
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
    description                                = optional(string)
  }))
  default = []

  validation {
    condition     = length(distinct([for r in var.custom_rules : r.name])) == length(var.custom_rules)
    error_message = "custom_rules names must be unique."
  }

  validation {
    condition     = alltrue([for r in var.custom_rules : r.priority >= 100 && r.priority <= 4095 && floor(r.priority) == r.priority])
    error_message = "custom_rules priorities must be whole numbers from 100 to 4095. 4096 is the DenyAll rule."
  }

  validation {
    condition     = alltrue([for r in var.custom_rules : contains(["Inbound", "Outbound"], r.direction) && contains(["Allow", "Deny"], r.access)])
    error_message = "custom_rules direction must be Inbound or Outbound, and access must be Allow or Deny."
  }

  validation {
    condition     = alltrue([for r in var.custom_rules : contains(["tcp", "udp", "icmp", "esp", "ah", "*"], lower(r.protocol))])
    error_message = "custom_rules protocol must be Tcp, Udp, Icmp, Esp, Ah or *."
  }

  validation {
    condition     = alltrue([for r in var.custom_rules : length([for s in [r.source_address_prefix, r.source_address_prefixes, r.source_application_security_group_ids] : s if s != null]) == 1])
    error_message = "Each custom rule must set exactly one of source_address_prefix, source_address_prefixes or source_application_security_group_ids."
  }

  validation {
    condition = alltrue(flatten([for r in var.custom_rules : [
      for l in [r.source_address_prefixes, r.source_application_security_group_ids, r.destination_address_prefixes, r.destination_application_security_group_ids] : length(l) > 0 if l != null
    ]]))
    error_message = "A source or destination list in custom_rules must have at least one entry when it is set."
  }

  validation {
    condition     = alltrue([for r in var.custom_rules : length([for d in [r.destination_address_prefix, r.destination_address_prefixes, r.destination_application_security_group_ids] : d if d != null]) <= 1])
    error_message = "Each custom rule may set at most one of destination_address_prefix, destination_address_prefixes or destination_application_security_group_ids."
  }

  validation {
    condition     = alltrue(flatten([for r in var.custom_rules : [for p in split(",", r.destination_port_range) : can(regex("^(\\*|[0-9]{1,5}(-[0-9]{1,5})?)$", trimspace(p)))]]))
    error_message = "custom_rules destination_port_range must be *, a port, a range such as 5985-5986, or a comma-separated list of those."
  }
}
