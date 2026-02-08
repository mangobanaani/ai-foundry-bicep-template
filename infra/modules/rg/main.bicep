@description('Resource group level deployments for AI Foundry solution with enhanced security')
param config object

@description('Object ID of the user to assign RBAC roles to. Leave empty to skip user role assignments.')
param userObjectId string = ''

// Deploy user-assigned managed identity (if enabled)
module identity '../shared/identity.bicep' = if (contains(config.identity, 'userAssigned') && contains(config.identity.userAssigned, 'enabled') && config.identity.userAssigned.enabled == true) {
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

// Deploy private endpoints for PaaS services (if networking enabled)
module privateEndpoints '../shared/private-endpoints.bicep' = if (config.networking.enabled == true) {
  name: 'private-endpoints'
  params: {
    config: config
    subnetId: networking.outputs.subnetId
    privateDnsZoneIds: networking.outputs.privateDnsZoneIds
  }
  dependsOn: [
    storage
    keyVault
    acr
    cognitive
  ]
}

// Deploy resource lock (if enabled)
module locks '../shared/locks.bicep' = {
  name: 'locks'
  params: {
    config: config
  }
}

// Deploy budget alerts (if enabled)
module budget '../shared/budget.bicep' = {
  name: 'budget'
  params: {
    config: config
  }
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

// Outputs - Resource names
@description('Storage account name')
output storageAccountName string = storage.outputs.storageAccountName

@description('Key Vault name')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('Container Registry name')
output acrName string = config.acr.enabled == true ? acr.outputs.acrName : ''

@description('Cognitive Services account name')
output cognitiveAccountName string = config.cognitive.enabled == true ? cognitive.outputs.name : ''

@description('AI Foundry Hub name')
output aiFoundryHubName string = aiFoundry.outputs.hubName

@description('AI Foundry Project name')
output aiFoundryProjectName string = aiFoundry.outputs.projectName

// Outputs - Resource IDs
@description('Storage account ID')
output storageAccountId string = storage.outputs.storageId

@description('Key Vault ID')
output keyVaultId string = keyVault.outputs.keyVaultId

@description('Container Registry ID')
output acrId string = config.acr.enabled == true ? acr.outputs.acrId : ''

@description('Cognitive Services account ID')
output cognitiveAccountId string = config.cognitive.enabled == true ? cognitive.outputs.id : ''

@description('AI Foundry Hub ID')
output aiFoundryHubId string = aiFoundry.outputs.hubId

@description('AI Foundry Project ID')
output aiFoundryProjectId string = aiFoundry.outputs.projectId

// Outputs - Endpoints
@description('Key Vault URI')
output keyVaultUri string = 'https://${config.keyVault.name}${environment().suffixes.keyvaultDns}'

@description('Cognitive Services endpoint')
output cognitiveEndpoint string = config.cognitive.enabled == true ? cognitive.outputs.endpoint : ''

@description('Container Registry login server')
output acrLoginServer string = config.acr.enabled == true ? '${config.acr.name}.azurecr.io' : ''

// Outputs - Principal IDs for automation
@description('AI Foundry Hub principal ID')
output hubPrincipalId string = aiFoundry.outputs.hubPrincipalId

@description('AI Foundry Project principal ID')
output projectPrincipalId string = aiFoundry.outputs.projectPrincipalId

@description('Storage account principal ID')
output storagePrincipalId string = storage.outputs.storagePrincipalId

// Outputs - Feature flags
@description('Whether resource lock is deployed')
output lockDeployed bool = locks.outputs.deployed

@description('Whether budget alerts are deployed')
output budgetDeployed bool = budget.outputs.deployed
