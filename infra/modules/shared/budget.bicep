// Monthly budget with cost alerts
// Deployed at resource group scope via Microsoft.Consumption/budgets

@description('Configuration object containing all settings')
param config object

@description('Budget start date in YYYY-MM-DD format. Defaults to first of current month.')
param budgetStartDate string = '${utcNow('yyyy-MM')}-01'

var budgetCfg = config.budget ?? {}
var enabled = budgetCfg.enabled ?? false
var amount = budgetCfg.amount ?? 1000
var contactEmails = budgetCfg.contactEmails ?? []
var budgetName = budgetCfg.name ?? 'budget-${config.resourceGroup.name}'
var startDate = budgetCfg.startDate ?? budgetStartDate

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = if (enabled && !empty(contactEmails)) {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      forecast80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        contactEmails: contactEmails
        thresholdType: 'Forecasted'
      }
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      actual100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      actual120: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 120
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
    }
  }
}

@description('Whether the budget was deployed')
output deployed bool = enabled && !empty(contactEmails)
