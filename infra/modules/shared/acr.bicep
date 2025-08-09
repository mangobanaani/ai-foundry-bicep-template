// Azure Container Registry with Enhanced Security Configuration
// Based on Microsoft's secure Azure AI Studio patterns

@description('Creates Azure Container Registry when enabled.')
param config object

var acr = config.acr
var location = config.location
var tags = config.tags ?? {}

// Security defaults based on Microsoft's secure templates
var securityDefaults = {
  // SKU - Premium required for private endpoints and advanced security
  sku: acr.sku ?? 'Premium'
  
  // Access controls
  adminUserEnabled: acr.adminUserEnabled ?? false
  publicNetworkAccess: acr.publicNetworkAccess ?? 'Disabled'
  dataEndpointEnabled: acr.dataEndpointEnabled ?? false
  
  // Network security
  networkRuleBypassOptions: acr.networkRuleBypassOptions ?? 'AzureServices'
  networkRuleSet: acr.networkRuleSet ?? {
    defaultAction: 'Deny'
  }
  
  // Zone redundancy
  zoneRedundancy: acr.zoneRedundancy ?? 'Disabled'
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acr.name
  location: location
  sku: {
    name: securityDefaults.sku
  }
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Access controls
    adminUserEnabled: securityDefaults.adminUserEnabled
    publicNetworkAccess: securityDefaults.publicNetworkAccess
    dataEndpointEnabled: securityDefaults.dataEndpointEnabled
    
    // Network security
    networkRuleBypassOptions: securityDefaults.networkRuleBypassOptions
    networkRuleSet: securityDefaults.networkRuleSet
    
    // Security policies (only supported properties)
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: acr.retentionDays ?? 7
      }
      trustPolicy: {
        status: securityDefaults.sku == 'Premium' ? 'enabled' : 'disabled'
        type: 'Notary'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    
    // Zone redundancy
    zoneRedundancy: securityDefaults.zoneRedundancy
    
    // Encryption
    encryption: {
      status: 'disabled' // Customer-managed keys can be enabled if needed
    }
  }
}

// Diagnostic settings if Log Analytics workspace is provided
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (contains(config, 'monitoring') && contains(config.monitoring, 'logAnalytics') && config.monitoring.logAnalytics.enabled == true) {
  scope: registry
  name: 'diagnosticSettings'
  properties: {
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', config.monitoring.logAnalytics.name)
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'ContainerRegistryLoginEvents'
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

output acrId string = registry.id

@description('Container Registry name')
output acrName string = registry.name

@description('Container Registry principal ID for RBAC')
output acrPrincipalId string = registry.identity.principalId
