# Azure AI Foundry Infrastructure

Bicep templates for deploying Azure AI Foundry Hub and Project with enterprise security controls.

## Structure

```
infra/
├── main.bicep                         # Subscription-level entry point
├── main.bicepparam                    # Default parameters
├── environments/
│   ├── dev.bicepparam                 # Development (public access, relaxed)
│   ├── staging.bicepparam             # Staging (public access, AAD-only auth)
│   └── prod.bicepparam                # Production (private networking, locked)
└── modules/
    ├── rg/main.bicep                  # Resource group orchestration
    └── shared/
        ├── ai-foundry.bicep           # AI Hub + Project
        ├── cognitive.bicep            # Azure AI Services
        ├── storage.bicep              # Storage account + containers
        ├── keyvault.bicep             # Key Vault
        ├── acr.bicep                  # Container Registry
        ├── monitoring.bicep           # Log Analytics + App Insights
        ├── networking.bicep           # VNet, subnets, DNS zones + VNet links
        ├── private-endpoints.bicep    # Private endpoints with DNS zone groups
        ├── identity.bicep             # User-assigned managed identity
        ├── rbac.bicep                 # Role assignments
        ├── locks.bicep                # Resource group delete lock
        └── budget.bicep               # Monthly budget with cost alerts
```

## Quick Start

### Prerequisites

- Azure CLI with Bicep extension
- Subscription Contributor role
- User Access Administrator role (for RBAC)

### Deploy

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
cd infra

# Validate
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters environments/dev.bicepparam

# Deploy
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters environments/dev.bicepparam
```

Replace `dev` with `staging` or `prod` for other environments.

## Environments

| Setting | Dev | Staging | Prod |
|---|---|---|---|
| Public network access | Enabled | Enabled | Disabled |
| Private endpoints | No | No | Yes |
| Local auth (API keys) | Allowed | Disabled | Disabled |
| Resource lock | No | No | CanNotDelete |
| Budget alerts | $500/mo | $2000/mo | $5000/mo |
| Log retention | 30 days | 90 days | 365 days |
| Storage redundancy | LRS | LRS | ZRS |
| Key Vault SKU | Standard | Standard | Premium (HSM) |
| Managed VNet isolation | Disabled | Disabled | AllowInternetOutbound |

## Security

- Managed identity for all resources (system-assigned + optional user-assigned)
- RBAC-based access control (no access policies)
- Private endpoints with automatic DNS registration (prod)
- DNS zone VNet links for private endpoint resolution
- Audit logging via Log Analytics
- Storage encryption, TLS 1.2 minimum, no shared key access
- Key Vault with purge protection and soft delete
- Container Registry with content trust and retention policies
- Cognitive Services with AAD-only authentication (staging/prod)

## Resource Locks and Budget

Resource locks prevent accidental deletion of production resource groups. The destroy workflow checks for locks and aborts if any are found.

Budget alerts notify configured contacts at 50%, 80%, 100%, and 120% of the monthly budget. A forecasted alert fires at 80%.

Configure via the `locks` and `budget` sections in parameter files:

```bicep
locks: {
  enabled: true
  name: 'rg-prod-delete-lock'
}
budget: {
  enabled: true
  amount: 5000
  contactEmails: ['devops-team@company.com']
}
```

## Configuration

Key parameters in environment files:

```bicep
config: {
  location: 'westeurope'
  cognitive: {
    enabled: true
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true
  }
  storage: {
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
  }
  networking: {
    enabled: true
    newVnet: true
    privateDnsZones: [
      'privatelink.blob.core.windows.net'
      'privatelink.vaultcore.azure.net'
      // ...
    ]
  }
  ai: {
    hub: {
      connectionAuthType: 'AAD'
      systemDatastoresAuthMode: 'identity'
      isolationMode: 'AllowInternetOutbound'
    }
  }
}
```

## Outputs

Deployments produce outputs for automation:

- Resource names and IDs (storage, key vault, ACR, cognitive, hub, project)
- Service endpoints (key vault URI, cognitive endpoint, ACR login server)
- Principal IDs (hub, project, storage) for downstream RBAC
- Feature flags (lock deployed, budget deployed)

## CI/CD

The GitHub Actions workflow supports `plan`, `deploy`, and `destroy` actions across dev, staging, and prod environments.

Destroying production requires typing `DESTROY` in the `confirm_destroy` input. The workflow also checks for resource locks and aborts if any exist.

Required secrets:

- `AZURE_CREDENTIALS` — service principal credentials JSON
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
