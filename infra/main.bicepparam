using 'main.bicep'

// Single source of truth for configuration. Adjust as needed.
param config = {
  location: 'westeurope'
  tags: {
    env: 'dev'
    owner: 'your-alias'
    solution: 'ai-foundry'
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
    name: 'stai${uniqueString('dev')}'
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: false
    containers: [
      { name: 'data' }
      { name: 'models' }
      { name: 'logs' }
    ]
  }
  keyVault: {
    name: 'kv-aif-dev-001'
    tenantId: '00000000-0000-0000-0000-000000000000' // Will be auto-detected at deployment
    skuName: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
  }
  acr: {
    enabled: false
    name: 'acraifdev001'
    sku: 'Basic'
  }
  networking: {
    enabled: false
    newVnet: true
    vnet: {
      name: 'vnet-aif-dev-001'
      addressPrefixes: ['10.100.0.0/16']
      subnets: [
        { name: 'snet-privatelink', addressPrefix: '10.100.1.0/24' }
      ]
    }
    privateDnsZones: [
      'privatelink.openai.azure.com'
      'privatelink.blob.core.windows.net'
      'privatelink.queue.core.windows.net'
      'privatelink.table.core.windows.net'
      'privatelink.file.core.windows.net'
    ]
  }
  cognitive: {
    enabled: true
    name: 'aoai-aif-dev-001'
    kind: 'AIServices'
    skuName: 'S0'
    publicNetworkAccess: 'Enabled'
    deployments: [
      // Example OpenAI deployments
      // {
      //   name: 'gpt-4o-mini'
      //   model: { format: 'OpenAI', name: 'gpt-4o-mini', version: '2024-07-18' }
      //   sku: { name: 'Standard', capacity: 50 }
      // }
    ]
  }
  ai: {
    hub: {
      name: 'aih-aif-dev-001'
      friendlyName: 'AI Foundry Hub - Development'
      description: 'Azure AI Foundry Hub for development environment'
      publicNetworkAccess: 'Enabled'
      systemDatastoresAuthMode: 'accessKey'
      connectionAuthType: 'ApiKey'
    }
    project: {
      name: 'aip-aif-dev-001'
      friendlyName: 'AI Foundry Project - Development'
      description: 'Azure AI Foundry Project for development'
      publicNetworkAccess: 'Enabled'
    }
  }
}
