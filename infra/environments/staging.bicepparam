using '../main.bicep'

// Staging environment configuration
// Between dev and prod: private networking disabled, AAD auth, no public blob access
param config = {
  location: 'westeurope'
  tags: {
    env: 'staging'
    owner: 'devops-team'
    solution: 'ai-foundry'
    costCenter: 'engineering'
    securityLevel: 'elevated'
  }
  resourceGroup: {
    name: 'rg-ai-foundry-staging'
  }
  identity: {
    userAssigned: {
      enabled: true
      name: 'uami-ai-foundry-staging'
    }
  }
  monitoring: {
    logAnalytics: {
      enabled: true
      name: 'law-aif-stg-001'
      sku: 'PerGB2018'
      retentionInDays: 90
    }
    appInsights: {
      enabled: true
      name: 'appi-aif-stg-001'
    }
  }
  storage: {
    name: 'staifstg${uniqueString(subscription().subscriptionId, 'staging')}'
    skuName: 'Standard_LRS'
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
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
    name: 'kv-aif-stg-001'
    tenantId: tenant().tenantId
    skuName: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 30
    publicNetworkAccess: 'Enabled'
  }
  acr: {
    enabled: true
    name: 'acraifstg001'
    sku: 'Premium'
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    anonymousPullEnabled: false
  }
  networking: {
    enabled: false // No private networking in staging
  }
  cognitive: {
    enabled: true
    name: 'cog-aif-stg-001'
    kind: 'AIServices'
    skuName: 'S0'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true // AAD only even in staging
    customSubDomainName: 'aif-stg-001'
    deployments: []
  }
  ai: {
    hub: {
      name: 'aih-aif-stg-001'
      friendlyName: 'AI Foundry Hub - Staging'
      description: 'Staging environment for AI Foundry workloads'
      publicNetworkAccess: 'Enabled'
      connectionAuthType: 'AAD'
      systemDatastoresAuthMode: 'identity'
      isolationMode: 'Disabled'
    }
    project: {
      name: 'aip-aif-stg-001'
      friendlyName: 'AI Foundry Project - Staging'
      description: 'Staging project for AI workloads'
      publicNetworkAccess: 'Enabled'
    }
  }
  locks: {
    enabled: false
  }
  budget: {
    enabled: true
    amount: 2000
    contactEmails: [
      'devops-team@company.com'
    ]
  }
}
