provider "azurerm" {
  features = {}
}

resource "azurerm_resource_group" "rg" {
  name     = "three-tier-rg"
  location = "eastus"
}

module "vnet" {
  source              = "../../modules/azure_vnet"
  name                = "three-tier-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.2.0.0/16"]
  dns_servers         = []
  tags = {
    environment = "prod"
  }
  subnets = [
    {
      name = "fw-subnet"
      address_prefixes = ["10.2.0.0/24"]
    },
    {
      name = "frontend-subnet"
      address_prefixes = ["10.2.1.0/24"]
    },
    {
      name = "backend-subnet"
      address_prefixes = ["10.2.2.0/24"]
    },
    {
      name = "db-subnet"
      address_prefixes = ["10.2.3.0/24"]
      delegation = [
        {
          name = "db-delegation"
          service_delegation = {
            actions = ["Microsoft.DBforMySQL/flexibleServers/action"]
            service_delegation_type = "Microsoft.DBforMySQL/flexibleServers"
          }
        }
      ]
    }
  ]
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "fw_pip" {
  name                = "fw-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Firewall in fw-subnet
resource "azurerm_firewall" "fw" {
  name                = "app-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = module.vnet.subnet_ids["fw-subnet"]
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  sku_name = "AZFW_VNet"
  sku_tier = "Standard"
}

# Frontend internal Load Balancer (receives traffic from Firewall via DNAT)
resource "azurerm_lb" "frontend" {
  name                = "frontend-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    subnet_id            = module.vnet.subnet_ids["frontend-subnet"]
    private_ip_address   = "10.2.1.4"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb" "backend" {
  name                = "backend-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = "backend-ip"
    subnet_id = module.vnet.subnet_ids["backend-subnet"]
    private_ip_address = "10.2.2.4"
    private_ip_address_allocation = "Static"
  }
}

# MySQL flexible server in db-subnet (private network)
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "threetier-mysql"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku_name = "Standard_B1ms"
  storage_mb = 32768
  version = "8.0"

  administrator_login          = "mysqladmin"
  administrator_password       = var.mysql_admin_password
  delegated_subnet_id          = module.vnet.subnet_ids["db-subnet"]

  high_availability = "Disabled"
  backup_retention_days = 7
}

# Firewall NAT rule collection to DNAT public port 80 to frontend LB private IP
resource "azurerm_firewall_nat_rule_collection" "dnat" {
  name                = "dnat-collection"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Dnat"

  nat_rule {
    name               = "dnat-http"
    rule_type          = "NetworkRule"
    source_addresses   = ["*"]
    destination_addresses = [azurerm_public_ip.fw_pip.ip_address]
    destination_ports  = ["80"]
    protocols          = ["Tcp"]
    translated_address = "10.2.1.4"
    translated_port    = "80"
  }
}

# Public DNS zone and A record for the firewall public IP (use a domain you control in production)
resource "azurerm_dns_zone" "zone" {
  name                = "three-tier.local"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "fw_record" {
  name                = "app"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.fw_pip.ip_address]
}

# CDN in front of the Firewall public IP (serves frontend content)
resource "azurerm_cdn_profile" "cdn" {
  name                = "three-tier-cdn"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "three-tier-endpoint"
  profile_name        = azurerm_cdn_profile.cdn.name
  resource_group_name = azurerm_resource_group.rg.name

  is_http_allowed  = true
  is_https_allowed = true

  origin {
    name      = "fw-origin"
    host_name = azurerm_dns_a_record.fw_record.fqdn
    http_port = 80
    https_port = 443
  }

  origin_host_header = azurerm_dns_a_record.fw_record.fqdn
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "cdn_hostname" {
  value = azurerm_cdn_endpoint.cdn_endpoint.host_name
}

output "fw_hostname" {
  description = "DNS name pointing to the firewall public IP"
  value       = azurerm_dns_a_record.fw_record.fqdn
}
