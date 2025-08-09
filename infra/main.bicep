targetScope = 'subscription'

@description('Global configuration for this deployment. Prefer configuring everything via the .bicepparam file.')
param config object

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
  }
}

output resourceGroupName string = rg.name
