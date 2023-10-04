# Network Security Group definition
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "security_group_name" {
  description = "Network security group name"
  type        = string
  default     = "nsg"
}

variable "nsg_tags" {
  type        = map(string)
  description = "Key/Value tags that should be added to the Network Security Group"
  default     = {}
}

variable "regional_tags" {
  type        = map(string)
  description = "Regional level tags"
}

variable "global_tags" {
  type        = map(string)
  description = "Global level tags"
}

variable "flowlog_tags" {
  type        = map(string)
  description = "Key/Value tags that should be added to Flow Logs"
  default     = {}
}

variable "location" {
  description = "Location (Azure Region) for the network security group."
  # No default - if it's not specified, use the resource group location (see main.tf)
  type    = string
  default = ""
}

# Security Rules definition 

# Predefined rules   
variable "predefined_rules" {
  type        = any
  description = "Set of built-in rule such as SSH or HTTPS "
  default     = []
}

# Custom security rules
# [priority, direction, access, protocol, source_port_range, destination_port_range, description]"
# All the fields are required.
variable "custom_rules" {
  description = "Security rules for the network security group using this format name = [priority, direction, access, protocol, source_port_range, destination_port_range, source_address_prefix, destination_address_prefix, description]"
  type        = any
  default     = []
}

# source address prefix to be applied to all predefined rules
# list(string) only allowed one element (CIDR, `*`, source IP range or Tags)
# Example ["10.0.3.0/24"] or ["VirtualNetwork"]
variable "source_address_prefix" {
  type        = list(string)
  description = "Source address prefix to be applied to all predefined rules"
  default     = ["*"]
}

# Destination address prefix to be applied to all predefined rules
# Example ["10.0.3.0/32","10.0.3.128/32"]
variable "source_address_prefixes" {
  type        = list(string)
  description = "Source address prefix to be applied to all predefined rules"
  default     = null
}

# Destination address prefix to be applied to all predefined rules
# list(string) only allowed one element (CIDR, `*`, source IP range or Tags)
# Example ["10.0.3.0/24"] or ["VirtualNetwork"]
variable "destination_address_prefix" {
  type        = list(string)
  description = "Destination address prefix to be applied to all predefined rules"
  default     = ["*"]
}

# Destination address prefix to be applied to all predefined rules
# Example ["10.0.3.0/32","10.0.3.128/32"]
variable "destination_address_prefixes" {
  type    = list(string)
  default = null
}

variable "storage_account_flowlogs_id" {
  type        = string
  description = "The ID of the Storage Account where flow logs are stored."
}

variable "network_watcher_flow_log_name" {
  type        = string
  description = "The name of the Network Watcher Flow Log"
}

variable "network_watcher_name" {
  type        = string
  description = "The name of the Network Watcher"
}

variable "network_watcher_flow_log_location" {
  description = "Location (Azure Region) for the network watcher flow logs."
  type        = string
  default     = "usgovvirginia" # same as network watcher
}

variable "diag_log_analytics_id" {
  description = "ID of the Log Analytics Workspace diagnostic logs should be sent to"
  type        = string
}

variable "diag_log_analytics_workspace_id" {
  description = "LAW Workspace ID (GUID) for traffic analytics logs"
  type        = string
}
