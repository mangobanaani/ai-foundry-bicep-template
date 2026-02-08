@description('Resource group level deployments for AI Foundry solution with enhanced security')
param config object

@description('Object ID of the user to assign RBAC roles to. Leave empty to skip user role assignments.')
param userObjectId string = ''

// Deploy user-assigned managed identity (if enabled)
module identity '../shared/identity.bicep' = if (config.identity.?userAssigned.?enabled == true) {
  name: 'identity'
  params: {
    config: config
  }
}

// Deploy networking resources (if enabled)
module networking '../shared/networking.bicep' = if (config.networking.enabled == true) {
  name: 'networking'
  params: {
    config: config
  }
}

// Deploy monitoring resources
module monitoring '../shared/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    config: config
  }
}

// Deploy storage resources with security hardening
module storage '../shared/storage.bicep' = {
  name: 'storage'
  params: {
    config: config
  }
}

// Deploy Key Vault with security hardening
module keyVault '../shared/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    config: config
    depStorageId: storage.outputs.storageId
  }
}

// Deploy Container Registry (if enabled)
module acr '../shared/acr.bicep' = if (config.acr.enabled == true) {
  name: 'acr'
  params: {
    config: config
  }
}

// Deploy AI Services (if enabled) with security hardening
module cognitive '../shared/cognitive.bicep' = if (config.cognitive.enabled == true) {
  name: 'cognitive'
  params: {
    config: config
  }
  dependsOn: [
    networking
  ]
}

// Deploy AI Foundry Hub and Project with security hardening
module aiFoundry '../shared/ai-foundry.bicep' = {
  name: 'ai-foundry'
  params: {
    config: config
  }
  dependsOn: [
    monitoring
    storage
    keyVault
    cognitive
    acr
  ]
}

// Deploy RBAC assignments for secure access
module rbac '../shared/rbac.bicep' = {
  name: 'rbac'
  params: {
    config: config
    userObjectId: userObjectId
    hubPrincipalId: aiFoundry.outputs.hubPrincipalId
    projectPrincipalId: aiFoundry.outputs.projectPrincipalId
    aiServicesPrincipalId: config.cognitive.enabled == true ? cognitive.outputs.principalId : ''
    storageAccountPrincipalId: storage.outputs.storagePrincipalId
    containerRegistryPrincipalId: config.acr.enabled == true ? acr.outputs.acrPrincipalId : ''
  }
  dependsOn: [
    aiFoundry
    cognitive
    acr
  ]
}

// Outputs
@description('Storage account name')
output storageAccountName string = storage.outputs.storageAccountName

@description('Key Vault name')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('AI Foundry Hub ID')
output aiFoundryHubId string = aiFoundry.outputs.hubId

@description('AI Foundry Project ID')
output aiFoundryProjectId string = aiFoundry.outputs.projectId
