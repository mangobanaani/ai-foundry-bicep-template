// Azure AI Services with Enhanced Security Configuration
// Based on Microsoft's secure Azure AI Studio patterns

@description('Creates Azure AI Services (formerly Cognitive Services) for AI Foundry.')
param config object

var cog = config.cognitive
var location = config.location
var tags = config.tags ?? {}

// Security defaults based on Microsoft's secure templates
var securityDefaults = {
  // Access controls
  publicNetworkAccess: cog.publicNetworkAccess ?? 'Disabled'
  disableLocalAuth: cog.disableLocalAuth ?? true
  
  // Network ACLs - deny by default with Azure services bypass
  networkAcls: cog.networkAcls ?? {
    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
  }
  
  // Custom subdomain for token-based authentication
  customSubDomainName: cog.customSubDomainName ?? ''
  
  // SKU with appropriate tier
  skuName: cog.skuName ?? 'S0'
}

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: cog.name
  kind: cog.kind // e.g., AIServices, OpenAI
  sku: {
    name: securityDefaults.skuName
  }
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Access and authentication
    publicNetworkAccess: securityDefaults.publicNetworkAccess
    disableLocalAuth: securityDefaults.disableLocalAuth
    customSubDomainName: !empty(securityDefaults.customSubDomainName) ? securityDefaults.customSubDomainName : cog.name
    
    // Network security
    networkAcls: securityDefaults.networkAcls
    
    // API properties
    apiProperties: cog.apiProperties ?? {}
    
    // User owned storage (if needed)
    userOwnedStorage: cog.userOwnedStorage ?? []
    
    // Encryption (if customer-managed keys are needed)
    encryption: cog.encryption ?? null
    
    // Restore settings
    restore: cog.restore ?? false
  }
}

// Model deployments for Azure OpenAI via subresource (ignore if not OpenAI)
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for d in (cog.deployments ?? []): {
  parent: account
  name: d.name
  properties: {
    model: {
      format: contains(d, 'model') && contains(d.model, 'format') ? d.model.format : 'OpenAI'
      name: d.model.name
      version: d.model.version
    }
    scaleSettings: {
      scaleType: contains(d, 'scaleSettings') && contains(d.scaleSettings, 'scaleType') ? d.scaleSettings.scaleType : 'Standard'
      capacity: contains(d, 'sku') && contains(d.sku, 'capacity') ? d.sku.capacity : 10
    }
    raiPolicyName: d.raiPolicyName ?? null
    versionUpgradeOption: d.versionUpgradeOption ?? 'OnceNewDefaultVersionAvailable'
  }
}]

// Diagnostic settings if Log Analytics workspace is provided
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (contains(config, 'monitoring') && contains(config.monitoring, 'logAnalytics') && config.monitoring.logAnalytics.enabled == true) {
  scope: account
  name: 'diagnosticSettings'
  properties: {
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', config.monitoring.logAnalytics.name)
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'RequestResponse'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Trace'
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

@description('AI Services account ID')
output id string = account.id

@description('AI Services account name')
output name string = account.name

@description('AI Services endpoint')
output endpoint string = account.properties.endpoint

@description('AI Services principal ID for RBAC')
output principalId string = account.identity.principalId

@description('AI Services custom subdomain name')
output customSubDomainName string = account.properties.customSubDomainName
