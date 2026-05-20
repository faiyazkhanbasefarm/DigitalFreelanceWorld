provider "azurerm" {
  features = {}
}

resource "azurerm_resource_group" "rg" {
  name     = "prod-rg"
  location = "eastus"
}

module "vnet" {
  source              = "../../modules/azure_vnet"
  name                = "prod-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.20.0.0/16"]
  tags = { environment = "prod" }
  subnets = [
    { name = "frontend"; address_prefixes = ["10.20.1.0/24"] },
    { name = "backend"; address_prefixes = ["10.20.2.0/24"] },
    { name = "db"; address_prefixes = ["10.20.3.0/24"], delegation = [
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

output "prod_vnet_id" { value = module.vnet.vnet_id }
