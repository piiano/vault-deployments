@description('Azure location')
param location string = resourceGroup().location

@description('The unique deployment id of this deployment')
param deploymentId string = 'pvault-server-exp1'

@description('The name Virtual Network (vnet) to deploy Piiano Vault resources in.')
param vnetName string

@description('The name of the subnet to deploy Piiano Vault resources in.')
param vnetSubnetId string

@description('OIDC issuer profile of the AKS cluster')
param aksOidcIssuerProfile string

@description('PostgreSQL admin password')
@secure()
param sqlAdminPassword string = newGuid()

@description('CosmosDB coordinator vCores')
param cosmosDBCoordinatorVCores int = 2

@description('CosmosDB server edition')
param cosmosDBServerEdition string = 'BurstableGeneralPurpose'

@description('CosmosDB coordinator storage quota in MB')
param cosmosDBCoordinatorStorageQuotaInMb int = 32768 // 32GB

@description('CosmosDB node storage quota in MB')
param cosmosDBNodeStorageQuotaInMb int = 524288 // 512GB

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param keyVaultSKU string = 'standard'

@description('Kubernetes namespace of the service account that will be attached to Piiano Vault pods.')
param pvaultNamespace string = 'pvault'

@description('Name of the service account that will be attached to Piiano Vault pods.')
param pvaultServiceAccountName string = 'pvault-sa'

// Existing.
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}
// --------- Postgres CosmosDB ---------
resource postgreServerGroup 'Microsoft.DBforPostgreSQL/serverGroupsv2@2022-11-08' = {
  name: deploymentId
  location: location
  properties: {
    postgresqlVersion: '14'
    administratorLoginPassword: sqlAdminPassword
    enableHa: false
    coordinatorVCores: cosmosDBCoordinatorVCores
    coordinatorServerEdition: cosmosDBServerEdition
    coordinatorStorageQuotaInMb: cosmosDBCoordinatorStorageQuotaInMb
    nodeVCores: 4
    nodeCount: 0
    nodeStorageQuotaInMb: cosmosDBNodeStorageQuotaInMb
    nodeEnablePublicIpAccess: false
  }
}

resource postgresPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${deploymentId}-pg-pe'
  location: location
  properties: {
    subnet: {
      id: vnetSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'postgres'
        properties: {
          privateLinkServiceId: postgreServerGroup.id
          groupIds: [
            'coordinator'
          ]
        }
      }
    ]
  }
}

resource postgresDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.postgres.cosmos.azure.com'
  location: 'global'
}

resource postgresVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: postgresDNSZone
  name: '${deploymentId}-pg-vnl'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: true
  }
}

resource postgresPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  #disable-next-line use-parent-property
  name: '${postgresPrivateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'postgres'
        properties: {
          privateDnsZoneId: postgresDNSZone.id
        }
      }
    ]
  }
}

@description('The hostname of the PostgreSQL server.')
output cosmosDBHostname string = postgreServerGroup.properties.serverNames[0].fullyQualifiedDomainName
@description('The name of the PostgreSQL database.')
output cosmosDBDatabase string = 'citus'
@description('The username of the PostgreSQL database.')
output cosmosDBUsername string = 'citus'
#disable-next-line outputs-should-not-contain-secrets
@description('The Key Vault secret name that holds the password of the PostgreSQL database.')
output cosmosDBPasswordSecret string = dbAdminPasswordSecret.id

// --------- KeyVault ---------
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: deploymentId
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: keyVaultSKU
    }
    publicNetworkAccess: 'enabled'

    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    // enableSoftDelete: keyVaultSoftDelete
    // enablePurgeProtection: keyVaultPurgeProtection ? true : null
  }
}

resource kek 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: keyVault
  name: 'pvault-kek'
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: true
      exportable: false
    }
  }
}

resource dbAdminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'pvault-server-admin-db-password'
  properties: {
    value: sqlAdminPassword
  }
}

@description('The name of the Key Vault that holds the encryption key and DB secret.')
output keyVaultName string = keyVault.name
@description('The URI of the Key Vault that holds the encryption key and DB secret.')
output keyVaultUri string = keyVault.properties.vaultUri
@description('The name of the Key Vault key that will be used by Piiano Vault KMS.')
output keyVaultKeyName string = kek.name
@description('The version of the Key Vault key that will be used by Piiano Vault KMS.')
output KeyVaultKeyVersion string = last(split(kek.properties.keyUriWithVersion, '/'))

// --------- IAM ---------
resource pvaultServerMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: '${deploymentId}-pvault-server'
  location: location

  resource fedCreds 'federatedIdentityCredentials' = {
    name: '${deploymentId}-pvault-server'
    properties: {
      audiences: [ 'api://AzureADTokenExchange' ]
      issuer: aksOidcIssuerProfile
      subject: 'system:serviceaccount:${pvaultNamespace}:${pvaultServiceAccountName}'
    }
  }
}
// Key Vault Crypto Service Encryption User.
var keyVaultCryptoUserRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')

resource kvAppGwSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, keyVaultCryptoUserRole, 'pvault-server')
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultCryptoUserRole
    principalId: pvaultServerMI.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The client id of the managed identity that will be used by Piiano Vault server to access Key Vault.')
output managedIdentityClientId string = pvaultServerMI.properties.clientId
