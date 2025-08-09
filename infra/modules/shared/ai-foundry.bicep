// AI Foundry Hub and Project Resources - Secure Configuration
// Based on Microsoft.MachineLearningServices resource provider as per official Microsoft templates
// Security patterns from: https://github.com/Azure-Samples/azure-ai-studio-secure-bicep

@description('Configuration object containing all settings')
param config object

var ai = config.ai
var location = config.location
var tags = config.tags ?? {}

// Build resource IDs for dependencies
var keyVaultId = resourceId('Microsoft.KeyVault/vaults', config.keyVault.name)
var storageAccountId = resourceId('Microsoft.Storage/storageAccounts', config.storage.name)
var applicationInsightsId = config.monitoring.appInsights.enabled != false ? resourceId('Microsoft.Insights/components', config.monitoring.appInsights.name) : ''
var containerRegistryId = config.acr.enabled == true ? resourceId('Microsoft.ContainerRegistry/registries', config.acr.name) : ''
var aiServicesId = resourceId('Microsoft.CognitiveServices/accounts', config.cognitive.name)
var workspaceId = resourceId('Microsoft.OperationalInsights/workspaces', config.monitoring.logAnalytics.name)

// Get AI Services resource for endpoint
resource aiServicesResource 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: config.cognitive.name
}

// Security defaults based on Microsoft's secure templates
var securityDefaults = {
  // Authentication - prefer AAD over API keys
  connectionAuthType: ai.hub.connectionAuthType ?? 'AAD'
  // Public access - disabled by default for security
  hubPublicNetworkAccess: ai.hub.publicNetworkAccess ?? 'Disabled'
  projectPublicNetworkAccess: ai.project.publicNetworkAccess ?? 'Disabled'
  // System datastores - use identity instead of access keys
  systemDatastoresAuthMode: ai.hub.systemDatastoresAuthMode ?? 'identity'
  // Network isolation - managed vnet with internet outbound
  isolationMode: ai.hub.isolationMode ?? 'AllowInternetOutbound'
}

// AI Foundry Hub (Azure Machine Learning workspace of kind 'Hub')
resource aiFoundryHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: ai.hub.name
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // organization
    friendlyName: ai.hub.friendlyName ?? ai.hub.name
    description: ai.hub.description ?? 'Azure AI Foundry Hub - Secure Configuration'

    // dependent resources
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: !empty(applicationInsightsId) ? applicationInsightsId : null
    containerRegistry: !empty(containerRegistryId) ? containerRegistryId : null

    // security configuration
    publicNetworkAccess: securityDefaults.hubPublicNetworkAccess
    systemDatastoresAuthMode: securityDefaults.systemDatastoresAuthMode
    hbiWorkspace: false // High Business Impact - set based on requirements
    v1LegacyMode: false
    
    // managed virtual network configuration
    managedNetwork: {
      isolationMode: securityDefaults.isolationMode
    }
  }

  // AI Services connection with secure authentication
  resource aiServicesConnection 'connections@2024-04-01-preview' = {
    name: '${ai.hub.name}-connection-aiservices'
    properties: {
      category: 'AIServices'
      target: aiServicesResource.properties.endpoint
      authType: securityDefaults.connectionAuthType
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
      }
      // Only use credentials for API key auth, AAD uses managed identity
      credentials: securityDefaults.connectionAuthType == 'ApiKey' ? {
        key: aiServicesResource.listKeys().key1
      } : null
    }
  }
}

// AI Foundry Project (Azure Machine Learning workspace of kind 'Project')
resource aiFoundryProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: ai.project.name
  location: location
  tags: tags
  kind: 'Project'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: ai.project.friendlyName ?? ai.project.name
    description: ai.project.description ?? 'Azure AI Foundry Project - Secure Configuration'
    publicNetworkAccess: securityDefaults.projectPublicNetworkAccess
    hubResourceId: aiFoundryHub.id
    systemDatastoresAuthMode: 'identity' // Always use identity for projects
    hbiWorkspace: false
    v1LegacyMode: false
  }
}

// Diagnostic settings for hub
resource hubDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(workspaceId)) {
  scope: aiFoundryHub
  name: 'diagnosticSettings'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

// Diagnostic settings for project
resource projectDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(workspaceId)) {
  scope: aiFoundryProject
  name: 'diagnosticSettings'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

@description('AI Foundry Hub resource ID')
output hubId string = aiFoundryHub.id

@description('AI Foundry Hub name')
output hubName string = aiFoundryHub.name

@description('AI Foundry Project resource ID')
output projectId string = aiFoundryProject.id

@description('AI Foundry Project name')
output projectName string = aiFoundryProject.name

@description('AI Foundry Hub principal ID')
output hubPrincipalId string = aiFoundryHub.identity.principalId

@description('AI Foundry Project principal ID')
output projectPrincipalId string = aiFoundryProject.identity.principalId
