@description('Creates managed identities and role assignments as configured.')
param config object

var identityCfg = config.identity
var location = config.location
var tags = config.tags ?? {}

var uamiEnabled = contains(identityCfg, 'userAssigned') && contains(identityCfg.userAssigned, 'enabled') && identityCfg.userAssigned.enabled == true

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (uamiEnabled) {
  name: uamiEnabled ? identityCfg.userAssigned.name : 'placeholder'
  location: location
  tags: tags
}

output principalId string = uamiEnabled ? uami.properties.principalId : ''
output userAssignedIdentityId string = uamiEnabled ? uami.id : ''
