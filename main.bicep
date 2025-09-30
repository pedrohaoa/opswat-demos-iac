@description('Ubicación para todos los recursos.')
param location string = resourceGroup().location

@description('Prefijo para los nombres de recursos para garantizar que sean únicos.')
param namePrefix string = 'opswat'

@description('Nombre de usuario para las VMs.')
param adminUsername string = 'azureuser'

@description('Contraseña para las VMs. Debe cumplir los requisitos de complejidad de Azure.')
@secure()
param adminPassword string

@description('ID de objeto de tu usuario de Azure para darte permisos en el Key Vault.')
param adminObjectId string

// Variables para nombres de recursos
var vnetName = '${namePrefix}-vnet'
var keyVaultName = '${namePrefix}-kv-${uniqueString(resourceGroup().id)}' // Nombre único global



// --- Módulo de Red ---
// Asumimos que opswat-demos-iac tiene un módulo de red o creamos uno simple.
// Por simplicidad, definiremos la red aquí directamente.
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-opswat'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-minio'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        // Bastion: nombre obligatorio y /26 mínimo
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        // Subred de administración (para jumpbox u otras VMs de ops)
        name: 'snet-admin'
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }  
    ]
  }
}

// --- Módulo de Key Vault e Identidad ---
module kv 'modules/keyvault.bicep' = {
  name: 'keyvaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    adminObjectId: adminObjectId
    minioRootUser: 'minioadmin'
    minioRootPassword: adminPassword // Reutilizamos la contraseña por simplicidad
  }
}

// --- Módulo de la VM de MinIO ---
module minio 'modules/minio-vm.bicep' = {
  name: 'minioVmDeployment'
  params: {
    location: location
    subnetId: vnet.properties.subnets[1].id // Usamos la segunda subred
    managedIdentityId: kv.outputs.managedIdentityId
    uamiClientId: kv.outputs.managedIdentityClientId
    keyVaultName: kv.outputs.keyVaultName
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

// --- Módulos de OPSWAT ---
// Aquí es donde integrarías las plantillas del repositorio clonado.
// Suponiendo que tengan un módulo 'md-core-vm.bicep' y 'mdss-vm.bicep'.

/*
// Ejemplo de cómo llamarías al módulo de MD Core
module mdCore 'opswat/md-core-vm.bicep' = {
  name: 'mdCoreDeployment'
  params: {
    location: location
    subnetId: vnet.properties.subnets[0].id // Usamos la primera subred
    adminUsername: adminUsername
    adminPassword: adminPassword
    // ... otros parámetros que requiera el módulo de OPSWAT
  }
}

// Ejemplo de cómo llamarías al módulo de MDSS
module mdss 'opswat/mdss-vm.bicep' = {
  name: 'mdssDeployment'
  params: {
    location: location
    subnetId: vnet.properties.subnets[0].id
    adminUsername: adminUsername
    adminPassword: adminPassword
    // ... otros parámetros
  }
}
*/


// --- DNS privado para Key Vault ---
resource kvPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource kvPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${namePrefix}-kv-vnetlink'
  parent: kvPrivateDns
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

// --- Private Endpoint para Key Vault ---
resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${namePrefix}-kv-pep'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id // snet-opswat
    }
    privateLinkServiceConnections: [
      {
        name: 'kv-connection'
        properties: {
          privateLinkServiceId: resourceId('Microsoft.KeyVault/vaults', keyVaultName)
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Vincula automáticamente la zona privada al PE (crea el A record)
resource kvPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = {
  name: 'kv-dnszonegroup'
  parent: kvPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'kv-zone'
        properties: {
          privateDnsZoneId: kvPrivateDns.id
        }
      }
    ]
  }
  dependsOn: [
    kvPrivateDnsLink
  ]
}

// Public IP para Bastion
resource pipBastion 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${namePrefix}-pip-bastion'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion Host
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: '${namePrefix}-bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: pipBastion.id
          }
        }
      }
    ]
  }
}


// Apuntar al Key Vault creado por tu módulo
resource kvExisting 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Apuntar al NSG de MinIO (nombre tal como lo definiste en modules/minio-vm.bicep)
resource nsgMinioExisting 'Microsoft.Network/networkSecurityGroups@2023-05-01' existing = {
  name: 'nsg-minio-vm'
}


@minValue(7)
@maxValue(730)
param lawRetentionDays int = 30

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${namePrefix}-law'
  location: location
  properties: {
    retentionInDays: lawRetentionDays
    features: {
      searchVersion: 2
    }
  }
}


// Diagnostic Settings para Key Vault -> Log Analytics
resource kvDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${namePrefix}-kv-to-law'
  scope: kvExisting
  properties: {
    workspaceId: law.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Diagnostic Settings para NSG de MinIO -> Log Analytics
resource nsgDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${namePrefix}-nsg-minio-to-law'
  scope: nsgMinioExisting
  properties: {
    workspaceId: law.id
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}


// --- Salidas ---
// (Si eliminaste el PIP del módulo de VM, este output quedará vacío/no aplicable)
output minioPublicIpAddress string = '' // conservado por compatibilidad; puedes eliminarlo
output minioPrivateIpAddress string = minio.outputs.minioPrivateIp
output minioConsoleUrlPrivate string = 'http://${minio.outputs.minioPrivateIp}:9001'
