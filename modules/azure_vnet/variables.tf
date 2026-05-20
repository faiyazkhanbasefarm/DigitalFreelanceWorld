variable "name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where VNet will be created"
  type        = string
}

variable "location" {
  description = "Azure region/location"
  type        = string
}

variable "address_space" {
  description = "List of address spaces for the VNet"
  type        = list(string)
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "List of subnets with configuration: name, address_prefixes (list), service_endpoints (list), delegation (list), network_security_group_id, route_table_id"
  type = list(object({
    name                    = string
    address_prefixes        = list(string)
    service_endpoints       = optional(list(string), [])
    delegation              = optional(list(object({
      name = string
      service_delegation = object({
        actions = list(string)
        service_delegation_type = string
      })
    })), [])
    network_security_group_id = optional(string)
    route_table_id = optional(string)
  }))
  default = []
}
