// Private Endpoints for PaaS services
// Creates private endpoints with DNS zone groups for automatic DNS registration

@description('Configuration object containing all settings')
param config object

@description('Subnet resource ID for private endpoint placement')
param subnetId string

@description('Array of private DNS zone resource IDs from networking module')
param privateDnsZoneIds array

var location = config.location
var tags = config.tags ?? {}
var netCfg = config.networking

// Map DNS zone names to their resource IDs for lookup
var dnsZoneNames = netCfg.privateDnsZones ?? []
var dnsZoneLookup = reduce(map(range(0, length(dnsZoneNames)), i => { '${dnsZoneNames[i]}': privateDnsZoneIds[i] }), {}, (cur, next) => union(cur, next))

// Build list of private endpoints to create based on deployed services
var storageEndpoints = [
  {
    name: 'pe-${config.storage.name}-blob'
    serviceId: resourceId('Microsoft.Storage/storageAccounts', config.storage.name)
    groupId: 'blob'
    dnsZoneName: 'privatelink.blob.core.windows.net'
  }
  {
    name: 'pe-${config.storage.name}-file'
    serviceId: resourceId('Microsoft.Storage/storageAccounts', config.storage.name)
    groupId: 'file'
    dnsZoneName: 'privatelink.file.core.windows.net'
  }
]

var keyVaultEndpoints = [
  {
    name: 'pe-${config.keyVault.name}-vault'
    serviceId: resourceId('Microsoft.KeyVault/vaults', config.keyVault.name)
    groupId: 'vault'
    dnsZoneName: 'privatelink.vaultcore.azure.net'
  }
]

var acrEndpoints = config.acr.enabled == true ? [
  {
    name: 'pe-${config.acr.name}-registry'
    serviceId: resourceId('Microsoft.ContainerRegistry/registries', config.acr.name)
    groupId: 'registry'
    dnsZoneName: 'privatelink.azurecr.io'
  }
] : []

var cognitiveEndpoints = config.cognitive.enabled == true ? [
  {
    name: 'pe-${config.cognitive.name}-account'
    serviceId: resourceId('Microsoft.CognitiveServices/accounts', config.cognitive.name)
    groupId: 'account'
    dnsZoneName: contains(dnsZoneNames, 'privatelink.cognitiveservices.azure.com') ? 'privatelink.cognitiveservices.azure.com' : 'privatelink.openai.azure.com'
  }
] : []

var allEndpoints = concat(storageEndpoints, keyVaultEndpoints, acrEndpoints, cognitiveEndpoints)

// Only create endpoints whose DNS zone is actually provisioned
var endpoints = filter(allEndpoints, ep => contains(dnsZoneNames, ep.dnsZoneName))

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2024-03-01' = [for ep in endpoints: {
  name: ep.name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: ep.name
        properties: {
          privateLinkServiceId: ep.serviceId
          groupIds: [ep.groupId]
        }
      }
    ]
  }
}]

resource dnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-03-01' = [for (ep, i) in endpoints: {
  parent: privateEndpoints[i]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(ep.dnsZoneName, '.', '-')
        properties: {
          privateDnsZoneId: dnsZoneLookup[ep.dnsZoneName]
        }
      }
    ]
  }
}]

@description('Deployed private endpoint resource IDs')
output privateEndpointIds array = [for (ep, i) in endpoints: privateEndpoints[i].id]
