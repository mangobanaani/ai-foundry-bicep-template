using '../main.bicep'

// Development environment configuration with security patterns
param config = {
  location: 'westeurope'
  tags: {
    env: 'dev'
    owner: 'devops-team'
    solution: 'ai-foundry'
    costCenter: 'engineering'
    securityLevel: 'standard'
  }
  resourceGroup: {
    name: 'rg-ai-foundry-dev'
  }
  identity: {
    userAssigned: {
      enabled: true
      name: 'uami-ai-foundry-dev'
    }
  }
  monitoring: {
    logAnalytics: {
      enabled: true
      name: 'law-aif-dev-001'
      sku: 'PerGB2018'
      retentionInDays: 30
    }
    appInsights: {
      enabled: true
      name: 'appi-aif-dev-001'
    }
  }
  storage: {
    name: 'staifdev${uniqueString(subscription().subscriptionId, 'dev')}'
    skuName: 'Standard_LRS'
    // Security settings - relaxed for dev but still secure
    publicNetworkAccess: 'Enabled' // Can be enabled for dev convenience
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false // Use identity-based access
    allowCrossTenantReplication: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    containers: [
      { name: 'data' }
      { name: 'models' }
      { name: 'logs' }
    ]
  }
  keyVault: {
    name: 'kv-aif-dev-001'
    tenantId: tenant().tenantId
    skuName: 'standard'
    // Security settings
    enableRbacAuthorization: true
    enablePurgeProtection: false // Dev can have purge protection disabled for easier cleanup
    enableSoftDelete: true
    softDeleteRetentionInDays: 7 // Shorter retention for dev
    publicNetworkAccess: 'Enabled' // Can be enabled for dev convenience
  }
  acr: {
    enabled: true // Enable for container testing
    name: 'acraifdev001'
    sku: 'Premium' // Use Premium for security features even in dev
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled' // Can be enabled for dev convenience
    anonymousPullEnabled: false
  }
  networking: {
    enabled: false // Public networking for dev convenience
  }
  cognitive: {
    enabled: true // Enable for AI services testing
    name: 'cog-aif-dev-001'
    kind: 'AIServices'
    skuName: 'S0'
    // Security settings - balanced for dev
    publicNetworkAccess: 'Enabled' // Can be enabled for dev convenience
    disableLocalAuth: false // Allow API keys for dev testing
    customSubDomainName: 'aif-dev-001'
  }
  ai: {
    hub: {
      name: 'aih-aif-dev-001'
      friendlyName: 'AI Foundry Hub - Development'
      description: 'Development environment for AI Foundry workloads'
      // Security settings - balanced for dev
      publicNetworkAccess: 'Enabled' // Can be enabled for dev convenience
      connectionAuthType: 'AAD' // Use AAD for better security
      systemDatastoresAuthMode: 'identity' // Use identity-based auth
      isolationMode: 'Disabled' // No managed vnet for dev
    }
    project: {
      name: 'aip-aif-dev-001'
      friendlyName: 'AI Foundry Project - Development'
      description: 'Development project for AI experiments'
      publicNetworkAccess: 'Enabled' // Can be enabled for dev convenience
    }
  }
}
