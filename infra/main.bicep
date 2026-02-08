targetScope = 'subscription'

@description('Global configuration for this deployment. Prefer configuring everything via the .bicepparam file.')
param config object

@description('Object ID of the user to assign RBAC roles to. Leave empty to skip user role assignments.')
param userObjectId string = ''

var location = config.location
var tags = config.tags ?? {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: config.resourceGroup.name
  location: location
  tags: tags
}

module rgDeploy 'modules/rg/main.bicep' = {
  name: 'rg-deploy'
  scope: resourceGroup(rg.name)
  params: {
    config: config
    userObjectId: userObjectId
  }
}

// Resource group
output resourceGroupName string = rg.name

// Resource names
output storageAccountName string = rgDeploy.outputs.storageAccountName
output keyVaultName string = rgDeploy.outputs.keyVaultName
output acrName string = rgDeploy.outputs.acrName
output cognitiveAccountName string = rgDeploy.outputs.cognitiveAccountName
output aiFoundryHubName string = rgDeploy.outputs.aiFoundryHubName
output aiFoundryProjectName string = rgDeploy.outputs.aiFoundryProjectName

// Resource IDs
output aiFoundryHubId string = rgDeploy.outputs.aiFoundryHubId
output aiFoundryProjectId string = rgDeploy.outputs.aiFoundryProjectId

// Endpoints
output keyVaultUri string = rgDeploy.outputs.keyVaultUri
output cognitiveEndpoint string = rgDeploy.outputs.cognitiveEndpoint
output acrLoginServer string = rgDeploy.outputs.acrLoginServer

// Principal IDs
output hubPrincipalId string = rgDeploy.outputs.hubPrincipalId
output projectPrincipalId string = rgDeploy.outputs.projectPrincipalId
