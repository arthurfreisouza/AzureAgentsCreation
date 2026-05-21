targetScope = 'resourceGroup'

@description('Object ID of the user, group, or service principal to assign the role to.')
param principalId string

@description('Role to assign at resource group scope.')
@allowed([
  'Owner'
  'Contributor'
  'Reader'
  'AcrPull'
])
param roleName string

@description('Type of the principal receiving the role.')
@allowed(['User', 'Group', 'ServicePrincipal'])
param principalType string = 'User'

var roleDefinitionIds = {
  Owner:       '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader:      'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  AcrPull:     '7f951dda-4ed3-4680-af7a-1e05135b3a49'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIds[roleName])
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = roleAssignment.id
