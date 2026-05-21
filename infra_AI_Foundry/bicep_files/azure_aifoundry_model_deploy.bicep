@description('Name of the existing AI Foundry account to deploy the model into.')
param foundryAccountName string

@description('Name of the model deployment. Must match MODEL_NAME in the agent .env file.')
param modelDeploymentName string = 'gpt-4.1'

@description('OpenAI model family to deploy.')
param modelName string = 'gpt-4.1'

@description('Specific model version.')
param modelVersion string = '2025-04-14'

@description('Model deployment SKU (e.g., GlobalStandard, Standard, ProvisionedManaged).')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity (thousand TPM for Standard SKUs).')
param modelCapacity int = 50

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundryAccount
  name: modelDeploymentName
  sku: {
    name: modelSkuName
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output modelDeploymentName string = modelDeployment.name
output foundryAccountName string = foundryAccount.name
