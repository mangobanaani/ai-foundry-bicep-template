// Role-Based Access Control (RBAC) Assignments
// Based on Microsoft's secure Azure AI Studio patterns

@description('Configuration object containing all settings')
param config object

@description('User Object ID for role assignments')
param userObjectId string = ''

@description('AI Hub principal ID')
param hubPrincipalId string = ''

@description('AI Project principal ID')
param projectPrincipalId string = ''

@description('AI Services principal ID')
param aiServicesPrincipalId string = ''

@description('Storage Account principal ID')
param storageAccountPrincipalId string = ''

@description('Container Registry principal ID')
param containerRegistryPrincipalId string = ''

// Built-in role definitions for Azure ML and AI services
resource azureMLDataScientistRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'f6c7c914-8db3-469d-8ca1-694a8f32e121' // AzureML Data Scientist
  scope: subscription()
}

resource azureMLComputeOperatorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'e503ece1-11d0-4e8e-8e2c-7a6c3bf38815' // AzureML Compute Operator
  scope: subscription()
}

resource cognitiveServicesUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User
  scope: subscription()
}

resource cognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
  scope: subscription()
}

resource storageAccountContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  scope: subscription()
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  scope: subscription()
}

resource storageFileDataPrivilegedContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '69566ab7-960f-475b-8e7c-b3118f30c6bd' // Storage File Data Privileged Contributor
  scope: subscription()
}

resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
  scope: subscription()
}

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
  scope: subscription()
}

// User role assignments for Azure ML workspace access
resource userDataScientistRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userObjectId)) {
  name: guid(resourceGroup().id, userObjectId, azureMLDataScientistRole.id, 'user-datascientist')
  properties: {
    roleDefinitionId: azureMLDataScientistRole.id
    principalId: userObjectId
    principalType: 'User'
  }
}

// AI Hub role assignments for storage access
resource hubStorageContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(hubPrincipalId)) {
  name: guid(resourceGroup().id, hubPrincipalId, storageAccountContributorRole.id, 'hub-storage')
  properties: {
    roleDefinitionId: storageAccountContributorRole.id
    principalId: hubPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource hubBlobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(hubPrincipalId)) {
  name: guid(resourceGroup().id, hubPrincipalId, storageBlobDataContributorRole.id, 'hub-blob')
  properties: {
    roleDefinitionId: storageBlobDataContributorRole.id
    principalId: hubPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource hubFileDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(hubPrincipalId)) {
  name: guid(resourceGroup().id, hubPrincipalId, storageFileDataPrivilegedContributorRole.id, 'hub-file')
  properties: {
    roleDefinitionId: storageFileDataPrivilegedContributorRole.id
    principalId: hubPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// AI Project role assignments
resource projectStorageContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(projectPrincipalId)) {
  name: guid(resourceGroup().id, projectPrincipalId, storageAccountContributorRole.id, 'project-storage')
  properties: {
    roleDefinitionId: storageAccountContributorRole.id
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource projectBlobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(projectPrincipalId)) {
  name: guid(resourceGroup().id, projectPrincipalId, storageBlobDataContributorRole.id, 'project-blob')
  properties: {
    roleDefinitionId: storageBlobDataContributorRole.id
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// AI Services role assignments for user access
resource userCognitiveServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userObjectId)) {
  name: guid(resourceGroup().id, userObjectId, cognitiveServicesUserRole.id, 'user-cognitive')
  properties: {
    roleDefinitionId: cognitiveServicesUserRole.id
    principalId: userObjectId
    principalType: 'User'
  }
}

resource userCognitiveServicesOpenAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userObjectId) && config.cognitive.kind == 'OpenAI') {
  name: guid(resourceGroup().id, userObjectId, cognitiveServicesOpenAIUserRole.id, 'user-openai')
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUserRole.id
    principalId: userObjectId
    principalType: 'User'
  }
}

// Container Registry role assignments (if ACR is enabled)
resource hubAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(hubPrincipalId) && config.acr.enabled == true) {
  name: guid(resourceGroup().id, hubPrincipalId, acrPullRole.id, 'hub-acr')
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: hubPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource projectAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(projectPrincipalId) && config.acr.enabled == true) {
  name: guid(resourceGroup().id, projectPrincipalId, acrPullRole.id, 'project-acr')
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: projectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// User role assignment for Key Vault access (if using RBAC)
resource userKeyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userObjectId) && (config.keyVault.enableRbacAuthorization ?? true)) {
  name: guid(resourceGroup().id, userObjectId, keyVaultSecretsUserRole.id, 'user-keyvault')
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole.id
    principalId: userObjectId
    principalType: 'User'
  }
}

@description('Indicates RBAC module completed successfully')
output deployed bool = true
