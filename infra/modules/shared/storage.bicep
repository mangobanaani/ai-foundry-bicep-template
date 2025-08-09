// Storage Account with Enhanced Security Configuration
// Based on Microsoft's secure Azure AI Studio patterns

@description('Creates a Storage Account and containers as configured.')
param config object

var st = config.storage
var location = config.location
var tags = config.tags ?? {}

// Security defaults based on Microsoft's secure templates
var securityDefaults = {
  // Access controls
  publicNetworkAccess: st.publicNetworkAccess ?? 'Disabled'
  allowBlobPublicAccess: st.allowBlobPublicAccess ?? false
  allowSharedKeyAccess: st.allowSharedKeyAccess ?? false
  allowCrossTenantReplication: st.allowCrossTenantReplication ?? false
  
  // Network security
  minimumTlsVersion: st.minimumTlsVersion ?? 'TLS1_2'
  supportsHttpsTrafficOnly: st.supportsHttpsTrafficOnly ?? true
  
  // Network ACLs - deny by default with Azure services bypass
  networkAcls: st.networkAcls ?? {
    bypass: 'AzureServices'
    defaultAction: 'Deny'
  }
  
  // Access tier and storage features
  accessTier: st.accessTier ?? 'Hot'
  isHnsEnabled: st.isHnsEnabled ?? false
  isNfsV3Enabled: st.isNfsV3Enabled ?? false
  largeFileSharesState: st.largeFileSharesState ?? 'Disabled'
}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: st.name
  location: location
  sku: {
    name: st.skuName ?? 'Standard_LRS'
  }
  kind: st.kind ?? 'StorageV2'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Access and security settings
    accessTier: securityDefaults.accessTier
    publicNetworkAccess: securityDefaults.publicNetworkAccess
    allowBlobPublicAccess: securityDefaults.allowBlobPublicAccess
    allowSharedKeyAccess: securityDefaults.allowSharedKeyAccess
    allowCrossTenantReplication: securityDefaults.allowCrossTenantReplication
    
    // Network security
    minimumTlsVersion: securityDefaults.minimumTlsVersion
    supportsHttpsTrafficOnly: securityDefaults.supportsHttpsTrafficOnly
    networkAcls: securityDefaults.networkAcls
    
    // Encryption settings
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    
    // Storage features
    isHnsEnabled: securityDefaults.isHnsEnabled
    isNfsV3Enabled: securityDefaults.isNfsV3Enabled
    largeFileSharesState: securityDefaults.largeFileSharesState
    
    // Key policy for key rotation
    keyPolicy: {
      keyExpirationPeriodInDays: st.keyExpirationPeriodInDays ?? 365
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    // Container soft delete
    containerDeleteRetentionPolicy: {
      enabled: true
      days: st.containerDeleteRetentionDays ?? 7
    }
    // Blob soft delete
    deleteRetentionPolicy: {
      enabled: true
      days: st.blobDeleteRetentionDays ?? 7
    }
    // Versioning
    isVersioningEnabled: st.isVersioningEnabled ?? true
    // Change feed
    changeFeed: {
      enabled: st.changeFeedEnabled ?? false
    }
  }
}

// File service with SMB security
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: st.fileDeleteRetentionDays ?? 7
    }
    protocolSettings: {
      smb: {
        versions: 'SMB3.0;SMB3.1.1'
        authenticationMethods: 'Kerberos'
        kerberosTicketEncryption: 'AES-256'
        channelEncryption: 'AES-256-GCM'
      }
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for c in (st.containers ?? []): {
  parent: blobService
  name: c.name
  properties: {
    publicAccess: c.publicAccess ?? 'None'
    metadata: c.metadata ?? {}
  }
}]

// Diagnostic settings if Log Analytics workspace is provided
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (contains(config, 'monitoring') && contains(config.monitoring, 'logAnalytics') && config.monitoring.logAnalytics.enabled == true) {
  scope: sa
  name: 'diagnosticSettings'
  properties: {
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', config.monitoring.logAnalytics.name)
    logs: [
      {
        category: 'StorageRead'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'StorageWrite'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'StorageDelete'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output storageId string = sa.id
output storageAccountName string = sa.name
