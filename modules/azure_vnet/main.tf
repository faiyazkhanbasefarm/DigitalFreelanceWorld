terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.73"
    }
  }
}

// provider block removed from module; provider must be configured in the root module (examples)

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_subnet" "this" {
  for_each = { for s in var.subnets : s.name => s }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  # address_prefixes is supported on newer provider versions; use address_prefix if single
  dynamic "address_prefixes" {
    for_each = length(each.value.address_prefixes) > 0 ? [1] : []
    content {
      address_prefixes = each.value.address_prefixes
    }
  }

  service_endpoints = lookup(each.value, "service_endpoints", null)
  delegation        = lookup(each.value, "delegation", null)

  # Optional associations
  network_security_group_id = lookup(each.value, "network_security_group_id", null)
  route_table_id            = lookup(each.value, "route_table_id", null)

  depends_on = [azurerm_virtual_network.this]
}
