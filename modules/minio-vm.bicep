 param location string
 param subnetId string
 param managedIdentityId string
 param uamiClientId string
 param keyVaultName string
 param adminUsername string
 @secure()
 param adminPassword string
 @minValue(50)
 param dataDiskSizeGB int = 512

// Cloud-Config (cloud-init) codificado en Base64
var cloudInit = base64(loadTextContent('../cloud-init/minio-cloud-config.yaml'))

// Grupo de Seguridad de Red (NSG)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-minio-vm'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
        // Solo permitimos SSH desde la VNet (p.ej. Bastion o salt-jump)
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowMinIO-API'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9000'
          // Restringimos al tráfico interno (MDSS en la misma VNet)
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowMinIO-Console'
        properties: {
          priority: 1020
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9001'
          // Solo gestión desde la VNet (snet-admin / Bastion)
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Interfaz de Red (NIC)
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-minio-vm'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          // Sin IP pública para cerrar exposición directa
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// Máquina Virtual de MinIO
resource minioVM 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-minio'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: dataDiskSizeGB
          managedDisk: {
            // Cambia a 'PremiumV2_LRS' si tu región lo soporta
            storageAccountType: 'Premium_LRS'
          }
          caching: 'None'
        }
      ]
    }
    osProfile: {
      computerName: 'minio-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: cloudInit // Inyectamos el cloud-config
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
   tags: {
     // Etiqueta para que el script cloud-init encuentre el Key Vault
     keyvaultName: keyVaultName
    // ClientId de la UAMI para pedir token a IMDS
    uamiClientId: uamiClientId
   }
 }
 
// IP privada útil para integraciones internas (MDSS)
output minioPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress