param name string
param location string

resource servicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  properties: {

  }
  sku: {
    name: 'Y1'
  }
  kind: 'linux'
}
