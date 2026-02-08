// Resource Locks for production protection
// Prevents accidental deletion of the resource group and its resources

@description('Configuration object containing all settings')
param config object

var lockCfg = config.locks ?? {}
var enabled = lockCfg.enabled ?? false

resource rgLock 'Microsoft.Authorization/locks@2020-05-01' = if (enabled) {
  name: lockCfg.name ?? 'rg-delete-lock'
  properties: {
    level: 'CanNotDelete'
    notes: lockCfg.notes ?? 'Protected resource group - remove lock before deletion'
  }
}

@description('Whether the lock was deployed')
output deployed bool = enabled
