# Azure AI Foundry Infrastructure

Bicep templates for deploying Azure AI Foundry Hub

## Structure

```
infra/
├── main.bicep
├── environments/
│   ├── dev.bicepparam
│   └── prod.bicepparam
└── modules/
    ├── rg/main.bicep
    └── shared/
        ├── ai-foundry.bicep
        ├── cognitive.bicep
        ├── storage.bicep
        ├── keyvault.bicep
        ├── acr.bicep
        ├── monitoring.bicep
        ├── networking.bicep
        └── rbac.bicep
```

## Quick Start

### Prerequisites
- Azure CLI with Bicep extension
- Subscription Contributor role
- User Access Administrator role (for RBAC)

### Deploy Development Environment
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

### Test Infrastructure
```bash
# Run validation tests
./test-infrastructure.sh
```

### Security Enhancements
- Managed identity for all resources
- RBAC-based access control
- Private endpoints support
- Audit logging enabled
- Storage encryption and access restrictions
- Key Vault with purge protection
- Container registry with trust policies

## Configuration

Key parameters in environment files:

```bicep
config: {
  location: 'westeurope'
  cognitive: {
    enabled: true
    publicNetworkAccess: 'Disabled'  // prod
    disableLocalAuth: true           // prod
  }
  storage: {
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'  // prod
  }
  ai: {
    hub: {
      connectionAuthType: 'AAD'
      systemDatastoresAuthMode: 'identity'
    }
  }
}
```

## CI/CD

Required secrets:
- `AZURE_CREDENTIALS`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`

