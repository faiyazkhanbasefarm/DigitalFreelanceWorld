provider "azurerm" {
  features = {}
}

resource "azurerm_resource_group" "rg" {
  name     = "dev-rg"
  location = "eastus"
}

module "vnet" {
  source              = "../../modules/azure_vnet"
  name                = "dev-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
  tags = { environment = "dev" }
  subnets = [
    { name = "frontend"; address_prefixes = ["10.10.1.0/24"] },
    { name = "backend"; address_prefixes = ["10.10.2.0/24"] },
    { name = "db"; address_prefixes = ["10.10.3.0/24"] , delegation = [
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

output "dev_vnet_id" { value = module.vnet.vnet_id }
