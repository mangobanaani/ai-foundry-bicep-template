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

output resourceGroupName string = rg.name
