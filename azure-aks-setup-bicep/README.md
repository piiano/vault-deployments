# Bicep / ARM for Piiano Vault on Azure AKS

This module deploys the resources that are necessary for Piiano Vault on run on an AKS cluster.

After setting up the resources, you can deploy Piiano Vault using the [Piiano Vault Helm chart](https://github.com/piiano/helm-charts/tree/main/charts/pvault-server).

## Installed Components

The following components are installed by default (some are optional):

| Name                                               | Description                                     | Remarks |
| -------------------------------------------------- | ----------------------------------------------- | ------- |
| Azure Cosmos DB for PostgreSQL                     | Azure Managed Postgres instance                 |         |
| Private Endpoint + Private DNS zone + Network Link | Private connection for Cosmos DB in vnet        |         |
| Key Vault key (RSA)                                | Used as encryption key for Piiano Vault         |         |
| Key Vault secret                                   | Placeholder for DB password                     |         |
| Managed Identity + Role assignment                 | Permissions to Piiano Vault to access Key Vault |         |

## Prerequisite resources

The module assumes the existence of:
* Virtual Network (vnet).
* AKS cluster with [OIDC issuer](https://learn.microsoft.com/en-us/azure/aks/use-oidc-issuer) enabled.

## Parameters

| Parameter                             | Description                                                                             | Type                    | Default                    |
| ------------------------------------- | --------------------------------------------------------------------------------------- | ----------------------- | -------------------------- |
| `aksOidcIssuerProfile`                | OIDC issuer profile of the AKS cluster                                                  | string                  |                            |
| `cosmosDBCoordinatorStorageQuotaInMb` | CosmosDB coordinator storage quota in MB                                                | int                     | 32768 // 32GB              |
| `cosmosDBCoordinatorVCores`           | CosmosDB coordinator vCores                                                             | int                     | 2                          |
| `cosmosDBNodeStorageQuotaInMb`        | CosmosDB node storage quota in MB                                                       | int                     | 524288 // 512GB            |
| `cosmosDBServerEdition`               | CosmosDB server edition                                                                 | string                  | 'BurstableGeneralPurpose'  |
| `deploymentId`                        | The unique deployment id of this deployment                                             | string                  | 'pvault-server-exp1'       |
| `keyVaultSKU`                         | Key Vault SKU                                                                           | 'premium' \| 'standard' | 'standard'                 |
| `location`                            | Azure location                                                                          | string                  | `resourceGroup().location` |
| `pvaultNamespace`                     | Kubernetes namespace of the service account that will be attached to Piiano Vault pods. | string                  | 'pvault'                   |
| `pvaultServiceAccountName`            | Name of the service account that will be attached to Piiano Vault pods.                 | string                  | 'pvault-sa'                |
| `sqlAdminPassword`                    | PostgreSQL admin password                                                               | string (secure)         | newGuid()                  |
| `vnetName`                            | The name Virtual Network (vnet) to deploy Piiano Vault resources in.                    | string                  |                            |
| `vnetSubnetId`                        | The name of the subnet to deploy Piiano Vault resources in.                             | string                  |                            |

## Referenced Resources

| Provider                                     | Name       | Scope |
| -------------------------------------------- | ---------- | ----- |
| Microsoft.Network/virtualNetworks@2021-05-01 | `vnetName` | -     |

## Resources

- [Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2022-01-31-preview](https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/2022-01-31-preview/userassignedidentities/federatedidentitycredentials)
- [Microsoft.Network/virtualNetworks@2021-05-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2021-05-01/virtualnetworks)
- [Microsoft.DBforPostgreSQL/serverGroupsv2@2022-11-08](https://learn.microsoft.com/en-us/azure/templates/microsoft.dbforpostgresql/2022-11-08/servergroupsv2)
- [Microsoft.Network/privateEndpoints@2023-04-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/privateendpoints)
- [Microsoft.Network/privateDnsZones@2020-06-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2020-06-01/privatednszones)
- [Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2020-06-01/privatednszones/virtualnetworklinks)
- [Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.network/2023-04-01/privateendpoints/privatednszonegroups)
- [Microsoft.KeyVault/vaults@2022-07-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/2022-07-01/vaults)
- [Microsoft.KeyVault/vaults/keys@2022-07-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/2022-07-01/vaults/keys)
- [Microsoft.KeyVault/vaults/secrets@2022-07-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/2022-07-01/vaults/secrets)
- [Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview](https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/2022-01-31-preview/userassignedidentities)
- [Microsoft.Authorization/roleAssignments@2022-04-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-04-01/roleassignments)

## Outputs

| Name                      | Type   | Description                                                                                         |
| ------------------------- | ------ | --------------------------------------------------------------------------------------------------- |
| `cosmosDBHostname`        | string | The hostname of the PostgreSQL server.                                                              |
| `cosmosDBDatabase`        | string | The name of the PostgreSQL database.                                                                |
| `cosmosDBUsername`        | string | The username of the PostgreSQL database.                                                            |
| `cosmosDBPasswordSecret`  | string | The Key Vault secret name that holds the password of the PostgreSQL database.                       |
| `keyVaultName`            | string | The name of the Key Vault that holds the encryption key and DB secret.                              |
| `managedIdentityClientId` | string | The client id of the managed identity that will be used by Piiano Vault server to access Key Vault. |