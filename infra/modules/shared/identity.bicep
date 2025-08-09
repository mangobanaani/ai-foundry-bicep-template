@description('Creates managed identities and role assignments as configured.')
param config object

var identityCfg = config.identity
var location = config.location
var tags = config.tags ?? {}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (identityCfg?.userAssigned?.enabled == true) {
  name: identityCfg.userAssigned.name
  location: location
  tags: tags
}

output principalId string = identityCfg?.userAssigned?.enabled == true ? uami.properties.principalId : ''
output userAssignedIdentityId string = identityCfg?.userAssigned?.enabled == true ? uami.id : ''
