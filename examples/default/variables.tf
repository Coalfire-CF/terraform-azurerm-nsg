variable "resource_group_name" {
  description = "Name of an existing resource group for the NSG."
  type        = string
}

variable "security_group_name" {
  description = "Name of the network security group."
  type        = string
  default     = "example-nsg"
}

variable "diag_log_analytics_id" {
  description = "Resource ID of the Log Analytics workspace that receives NSG diagnostic logs."
  type        = string
}

variable "management_cidrs" {
  description = "CIDRs allowed to reach SSH. Never use * or Internet here."
  type        = list(string)
  default     = ["10.10.0.0/24"]
}

variable "tags" {
  description = "Tags applied to the NSG."
  type        = map(string)
  default     = {}
}
