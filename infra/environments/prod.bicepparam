using '../main.bicep'

// Production environment configuration with full security hardening
// Based on Microsoft's secure Azure AI Studio patterns
param config = {
  location: 'westeurope'
  tags: {
    env: 'prod'
    owner: 'devops-team'
    solution: 'ai-foundry'
    costCenter: 'production'
    securityLevel: 'high'
    compliance: 'required'
  }
  resourceGroup: {
    name: 'rg-ai-foundry-prod'
  }
  identity: {
    userAssigned: {
      enabled: true
      name: 'uami-ai-foundry-prod'
    }
  }
  monitoring: {
    logAnalytics: {
      enabled: true
      name: 'law-aif-prod-001'
      sku: 'PerGB2018'
      retentionInDays: 365 // Long retention for compliance
    }
    appInsights: {
      enabled: true
      name: 'appi-aif-prod-001'
    }
  }
  storage: {
    name: 'staifprod${uniqueString(subscription().subscriptionId, 'prod')}'
    skuName: 'Standard_ZRS' // Zone redundancy for production
    // Maximum security settings for production
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false // Identity-based access only
    allowCrossTenantReplication: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    // Network ACLs with deny default
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    // Extended retention and features
    containerDeleteRetentionDays: 30
    blobDeleteRetentionDays: 30
    isVersioningEnabled: true
    keyExpirationPeriodInDays: 90 // Frequent key rotation
    containers: [
      { name: 'data' }
      { name: 'models' }
      { name: 'logs' }
      { name: 'backups' }
    ]
  }
  keyVault: {
    name: 'kv-aif-prod-001'
    tenantId: tenant().tenantId
    skuName: 'premium' // Premium for HSM support
    // Maximum security settings
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    // Network ACLs with deny default
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
  }
  acr: {
    enabled: true
    name: 'acraifprod001'
    sku: 'Premium' // Premium required for security features
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
    }
    retentionDays: 30
    softDeleteRetentionDays: 30
    zoneRedundancy: 'Enabled'
  }
  networking: {
    enabled: true // Enable networking for private endpoints
    newVnet: true
    vnet: {
      name: 'vnet-aif-prod-001'
      addressPrefixes: ['10.0.0.0/16']
      subnets: [
        {
          name: 'snet-ai-services'
          addressPrefix: '10.0.1.0/24'
        }
        {
          name: 'snet-private-endpoints'
          addressPrefix: '10.0.2.0/24'
        }
      ]
    }
    privateDnsZones: [
      'privatelink.openai.azure.com'
      'privatelink.cognitiveservices.azure.com'
      'privatelink.blob.core.windows.net'
      'privatelink.queue.core.windows.net'
      'privatelink.table.core.windows.net'
      'privatelink.file.core.windows.net'
      'privatelink.vaultcore.azure.net'
      'privatelink.azurecr.io'
    ]
  }
  cognitive: {
    enabled: true
    name: 'cog-aif-prod-001'
    kind: 'AIServices'
    skuName: 'S0'
    // Maximum security settings
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: true // No API keys, AAD only
    customSubDomainName: 'aif-prod-001'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    deployments: []
  }
  ai: {
    hub: {
      name: 'aih-aif-prod-001'
      friendlyName: 'AI Foundry Hub - Production'
      description: 'Production environment for AI Foundry workloads with enhanced security'
      // Maximum security settings
      publicNetworkAccess: 'Disabled'
      connectionAuthType: 'AAD' // AAD authentication only
      systemDatastoresAuthMode: 'identity' // Identity-based auth only
      isolationMode: 'AllowInternetOutbound' // Managed virtual network
    }
    project: {
      name: 'aip-aif-prod-001'
      friendlyName: 'AI Foundry Project - Production'
      description: 'Production project for AI workloads with enhanced security'
      publicNetworkAccess: 'Disabled'
    }
  }
}
