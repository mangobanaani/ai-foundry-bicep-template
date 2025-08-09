@description('Provision virtual network, subnets, and Private DNS zones for private networking.')
param config object

var location = config.location
var tags = config.tags ?? {}
var netCfg = config.networking

resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' = if (netCfg.newVnet == true) {
  name: netCfg.vnet.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: netCfg.vnet.addressPrefixes
    }
    subnets: [for s in netCfg.vnet.subnets: {
      name: s.name
      properties: {
        addressPrefix: s.addressPrefix
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Disabled'
      }
    }]
  }
}

// Create Private DNS zones if requested
resource pdnsz 'Microsoft.Network/privateDnsZones@2020-06-01' = [for z in (netCfg.privateDnsZones ?? []): {
  name: z
  location: 'global'
  tags: tags
}]

// Compute output values
var vnetId = netCfg.existingVnetResourceId ?? (netCfg.newVnet == true ? vnet.id : '')
var subnetId = netCfg.subnetResourceId ?? (netCfg.newVnet == true && length(netCfg.vnet.subnets) > 0 ? resourceId('Microsoft.Network/virtualNetworks/subnets', netCfg.vnet.name, netCfg.vnet.subnets[0].name) : '')

output vnetId string = vnetId
output subnetId string = subnetId
output privateDnsZoneIds array = [for (z, i) in (netCfg.privateDnsZones ?? []): pdnsz[i].id]
