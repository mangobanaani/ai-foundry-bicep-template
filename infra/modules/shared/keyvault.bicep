// Key Vault with Enhanced Security Configuration
// Based on Microsoft's secure Azure AI Studio patterns

@description('Creates Key Vault and optional access policies / RBAC. Supports private endpoints via networking module.')
param config object
@description('Optional dependency on storage for keyvault diagnostic settings or access policy references.')
param depStorageId string

var kv = config.keyVault
var location = config.location
var tags = config.tags ?? {}

// Security defaults based on Microsoft's secure templates
var securityDefaults = {
  // Access controls
  publicNetworkAccess: kv.publicNetworkAccess ?? 'Disabled'
  enableRbacAuthorization: kv.enableRbacAuthorization ?? true
  
  // Security features
  enablePurgeProtection: kv.enablePurgeProtection ?? true
  enableSoftDelete: kv.enableSoftDelete ?? true
  softDeleteRetentionInDays: kv.softDeleteRetentionInDays ?? 90
  
  // Feature enablement
  enabledForDeployment: kv.enabledForDeployment ?? false
  enabledForDiskEncryption: kv.enabledForDiskEncryption ?? false
  enabledForTemplateDeployment: kv.enabledForTemplateDeployment ?? false
  
  // Network ACLs - deny by default with Azure services bypass
  networkAcls: kv.networkAcls ?? {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
  }
  
  // SKU
  skuName: kv.skuName ?? 'standard'
}

resource kvRes 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kv.name
  location: location
  tags: tags
  properties: {
    tenantId: kv.tenantId != '00000000-0000-0000-0000-000000000000' ? kv.tenantId : tenant().tenantId
    sku: {
      family: 'A'
      name: securityDefaults.skuName
    }
    
    // RBAC and access controls
    enableRbacAuthorization: securityDefaults.enableRbacAuthorization
    publicNetworkAccess: securityDefaults.publicNetworkAccess
    networkAcls: securityDefaults.networkAcls
    
    // Security and compliance
    enablePurgeProtection: securityDefaults.enablePurgeProtection
    enableSoftDelete: securityDefaults.enableSoftDelete
    softDeleteRetentionInDays: securityDefaults.softDeleteRetentionInDays
    
    // Feature enablement
    enabledForDeployment: securityDefaults.enabledForDeployment
    enabledForDiskEncryption: securityDefaults.enabledForDiskEncryption
    enabledForTemplateDeployment: securityDefaults.enabledForTemplateDeployment
    
    // Access policies (only used when RBAC is disabled)
    accessPolicies: securityDefaults.enableRbacAuthorization ? [] : (kv.accessPolicies ?? [])
  }
}

// Diagnostic settings if Log Analytics workspace is provided
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (contains(config, 'monitoring') && contains(config.monitoring, 'logAnalytics') && config.monitoring.logAnalytics.enabled == true) {
  scope: kvRes
  name: 'diagnosticSettings'
  properties: {
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', config.monitoring.logAnalytics.name)
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output keyVaultId string = kvRes.id
output keyVaultName string = kvRes.name
