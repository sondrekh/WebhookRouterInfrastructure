@description('Specifies the location for resources.')
param location string = 'northeurope'

param rgName string
param storageName string
param serviceName string

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module storage 'storage.bicep' = {
  name: 'storageModule'
  scope: resourceGroup
  params: {
    storageLocation: location
    storageName: storageName
  }
}

module servicePlan 'appserviceplan.bicep' = {
  name: 'serviceModule'
  scope: resourceGroup
  params: {
    location: location
    name: serviceName
  }
}
