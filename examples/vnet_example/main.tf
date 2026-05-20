module "vnet" {
  source              = "../../modules/azure_vnet"
  name                = "example-vnet"
  resource_group_name = "example-rg"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = []
  tags = {
    environment = "dev"
  }
  subnets = [
    {
      name = "subnet-1"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name = "subnet-2"
      address_prefixes = ["10.0.2.0/24"]
      network_security_group_id = null
    }
  ]
}

module "vnet2" {
  source              = "../../modules/azure_vnet"
  name                = "example-vnet-2"
  resource_group_name = "example-rg"
  location            = "eastus"
  address_space       = ["10.1.0.0/16"]
  dns_servers         = []
  tags = {
    environment = "dev"
  }
  subnets = [
    {
      name = "subnet-1"
      address_prefixes = ["10.1.1.0/24"]
    }
  ]
}

resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                      = "vnet1-to-vnet2"
  resource_group_name       = "example-rg"
  virtual_network_name      = module.vnet.vnet_name
  remote_virtual_network_id = module.vnet2.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                      = "vnet2-to-vnet1"
  resource_group_name       = "example-rg"
  virtual_network_name      = module.vnet2.vnet_name
  remote_virtual_network_id = module.vnet.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
