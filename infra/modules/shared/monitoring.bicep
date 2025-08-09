@description('Creates Log Analytics Workspace and Application Insights as configured.')
param config object

var mon = config.monitoring
var location = config.location
var tags = config.tags ?? {}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: mon.logAnalytics.name
  location: location
  tags: tags
  properties: {
    sku: {
      name: mon.logAnalytics.sku ?? 'PerGB2018'
    }
    retentionInDays: mon.logAnalytics.retentionInDays ?? 30
    publicNetworkAccessForIngestion: mon.logAnalytics.publicNetworkAccessForIngestion ?? 'Enabled'
    publicNetworkAccessForQuery: mon.logAnalytics.publicNetworkAccessForQuery ?? 'Enabled'
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: mon.appInsights.name
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
  }
}

output logAnalyticsId string = law.id
output appInsightsId string = appi.id
