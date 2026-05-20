# 🏗️ Azure Terraform Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-%230072C6.svg?style=flat&logo=microsoftazure&logoColor=white)
![HCL](https://img.shields.io/badge/HCL-%235835CC.svg?style=flat&logo=terraform&logoColor=white)

Production-ready Terraform modules for Azure cloud infrastructure — reusable VNet module, three-tier architecture, and full environment separation.

> 🔒 No credentials, subscription IDs, or tenant IDs are stored in this repository.  
> Use `terraform.tfvars` (gitignored) or environment variables (`ARM_*`) for authentication.

---

## Modules

### `modules/azure_vnet`

A reusable **Azure Virtual Network** module that provisions:

- Virtual Network with configurable address space
- Multiple subnets with per-subnet CIDR configuration
- Network Security Groups (NSGs)
- Route tables with custom UDR support
- Service endpoint delegation
- Bidirectional VNet peering

---

## Examples

### `examples/three_tier`

Three-tier application network topology:

| Tier | Resources |
|---|---|
| Edge / Security | Azure Firewall (Premium) with DNAT rules |
| Web Tier | Public Load Balancer · Web subnet · NSG |
| App Tier | Internal Load Balancer · App subnet · NSG |
| Data Tier | MySQL Flexible Server · delegated subnet · Private DNS |
| CDN / DNS | Azure CDN · Azure DNS Zone |

### `examples/vnet_example`

Two-VNet bidirectional peering using the `azure_vnet` module.

### `examples/dev` / `examples/prod`

Environment-separated VNets — relaxed NSGs for dev, strict least-privilege rules for prod.

---

## Architecture — Three-Tier

```
                    ┌─────────────────────┐
                    │      Internet        │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Azure Firewall    │
                    │  (DNAT · Policy)     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Web Tier Subnet    │
                    │ Public Load Balancer │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   App Tier Subnet    │
                    │ Internal Load Balancer│
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Data Tier Subnet   │
                    │  MySQL Flexible Srv  │
                    │  Private DNS Zone    │
                    └─────────────────────┘
```

---

## Usage

```hcl
module "app_vnet" {
  source = "../../modules/azure_vnet"

  vnet_name           = "vnet-prod-eastus"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name              = "snet-web"
      address_prefix    = "10.0.1.0/24"
      service_endpoints = ["Microsoft.Web"]
      delegation        = null
    },
    {
      name              = "snet-app"
      address_prefix    = "10.0.2.0/24"
      service_endpoints = []
      delegation        = null
    },
    {
      name              = "snet-data"
      address_prefix    = "10.0.3.0/24"
      service_endpoints = ["Microsoft.Sql"]
      delegation        = "Microsoft.DBforMySQL/flexibleServers"
    }
  ]

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

---

## Authentication

Credentials are **never** stored in code. Use one of:

```bash
# Option 1 – Azure CLI (local dev)
az login
az account set --subscription "$SUBSCRIPTION_ID"

# Option 2 – Environment variables (CI/CD)
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
```

A `terraform.tfvars` file (gitignored) can hold non-secret variable overrides for local development.

---

## Requirements

| Requirement | Version |
|---|---|
| Terraform | `>= 1.3` |
| azurerm provider | `>= 3.0` |
| Azure CLI | `>= 2.40` |

See [AUTHENTICATION.md](../../AUTHENTICATION.md) for Service Principal setup details.
