@description('The name of the person/owner for the naming convention.')
param personName string

@description('Specifies the name of the environment (e.g., dev, prod).')
param environment string

@description('Specifies the location of the resources.')
@allowed([
    'australiaeast'
    'brazilsouth'
    'canadacentral'
    'centralus'
    'eastasia'
    'eastus'
    'eastus2'
    'francecentral'
    'japaneast'
    'koreacentral'
    'northcentralus'
    'northeurope'
    'southeastasia'
    'southcentralus'
    'uksouth'
    'westcentralus'
    'westus'
    'westus2'
    'westeurope'
    'usgovvirginia'
  ])
param location string

@description('Display name for the default Foundry project.')
param projectDisplayName string = 'Default Project'

@description('Description for the default Foundry project.')
param projectDescription string = 'Default AI Foundry project'

// ── Naming ────────────────────────────────────────────────────────────────────
var baseName      = toLower('${personName}-${environment}')
var baseNameClean = replace(replace(baseName, '-', ''), '_', '') // alphanumeric only

var foundryAccountName     = take('aif-${baseName}', 64)
var foundryProjectName     = take('proj-${baseName}', 64)
var customSubDomain        = take(replace('aif-${baseName}', '_', '-'), 64)
var storageAccountName     = toLower(take('st${baseNameClean}', 24))
var keyVaultName           = take('kv-${baseName}', 24)
var logAnalyticsName       = 'law-${baseName}'
var appInsightsName        = 'appi-${baseName}'
var containerRegistryName  = toLower(take('cr${baseNameClean}', 50))

// ── Storage Account ───────────────────────────────────────────────────────────
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: { enabled: true }
        file: { enabled: true }
      }
    }
  }
}

// ── Key Vault ─────────────────────────────────────────────────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enableSoftDelete: true
    enableRbacAuthorization: true
  }
}

// ── Log Analytics Workspace (backing store for App Insights) ──────────────────
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ── Application Insights ──────────────────────────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ── Container Registry ────────────────────────────────────────────────────────
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

// ── AI Foundry Account ────────────────────────────────────────────────────────
// CognitiveServices/accounts kind=AIServices (GA 2025).
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: customSubDomain
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  // Companion resources should exist before the Foundry account is created
  dependsOn: [
    storageAccount
    keyVault
    appInsights
    containerRegistry
  ]
}

// ── AI Foundry Project ────────────────────────────────────────────────────────
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundryAccount
  name: foundryProjectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectDisplayName
    description: projectDescription
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output foundryAccountName    string = foundryAccount.name
output foundryProjectName    string = foundryProject.name
output foundryEndpoint       string = foundryAccount.properties.endpoint
output storageAccountName    string = storageAccount.name
output keyVaultName          string = keyVault.name
output appInsightsName       string = appInsights.name
output containerRegistryName string = containerRegistry.name
output logAnalyticsName      string = logAnalyticsWorkspace.name
