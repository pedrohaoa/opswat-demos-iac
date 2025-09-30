@description('Nombre del Key Vault.')
param keyVaultName string

@description('Ubicación para los recursos.')
param location string

@description('ID de objeto de tu usuario de Azure para conceder permisos. Ejecuta "az ad signed-in-user show --query id -o tsv" en la terminal.')
param adminObjectId string

@description('Usuario raíz para MinIO.')
@secure()
param minioRootUser string

@description('Contraseña raíz para MinIO.')
@secure()
param minioRootPassword string

// Identidad Administrada para la VM de MinIO
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-minio-vm'
  location: location
}

// Key Vault para almacenar los secretos
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true // Usar RBAC para el control de acceso
  }
}

// Asignar rol a la Identidad Administrada para que pueda leer secretos
resource identityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, managedIdentity.id, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Asignar rol al administrador para que pueda gestionar los secretos
resource adminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, adminObjectId, 'Key Vault Administrator')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483') // Key Vault Administrator
    principalId: adminObjectId
  }
}

// Secretos para MinIO
resource minioUserSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'minio-root-user'
  properties: {
    value: minioRootUser
  }
}

resource minioPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'minio-root-password'
  properties: {
    value: minioRootPassword
  }
}

// Salidas del módulo
output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output keyVaultName string = keyVault.name