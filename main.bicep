@description('The name of the function app that you wish to create.')
param appName string = 'skh-webhook'
param topicName string = 'router'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])

param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}


// Service plan (consumption)
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}


// Service bus namespace
resource service_bus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: 'sb-webhook-skh'
  location: location
  sku: {
    name: 'Standard'  
  }
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  name: topicName
  parent: service_bus
  properties: {
    defaultMessageTimeToLive: 'PT2H'
  }
}

// Subscription for receiving messages with contact updates
resource contactSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  name: 'contacts'
  parent: topic
  properties: {
    defaultMessageTimeToLive: 'PT12H'
    maxDeliveryCount: 1
  }
}

// Subscription for receiving messages with account updates
resource accountSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  name: 'accounts'
  parent: topic
  properties: {
    defaultMessageTimeToLive: 'PT12H'

// All messages for debugging purposes
resource all 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  name: 'all_messages'
  parent: topic
  properties: {
    defaultMessageTimeToLive: 'PT1H'
    maxDeliveryCount: 1
  }
}


// Adding filter for filtering out messages labeled with "contact"
resource contactFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-01-01-preview' = {
  name: 'contactFilter'
  parent: contactSubscription
  properties: {
    correlationFilter: {
      properties: {
        entity: 'contact'
      }
    }
    filterType: 'CorrelationFilter'
  }
}

// Adding filter for filtering out messages labeled with "account"
resource accountFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-01-01-preview' = {
  name: 'accountFilter'
  parent: accountSubscription
  properties: {
    correlationFilter: {
      properties: {
        entity: 'account'
      }
    }
    filterType: 'CorrelationFilter'
  }
}


// Extracting connection string from created servicebus namespace to add to app settings in function app
var serviceBusEndpoint = '${service_bus.id}/AuthorizationRules/RootManageSharedAccessKey'
var serviceBusConnectionString = listKeys(serviceBusEndpoint, service_bus.apiVersion).primaryConnectionString

// Function app with reference to dependencies
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'SERVICE_BUS_CONNECTION_STRING'
          value: serviceBusConnectionString
        }
        {
          name: 'TOPIC_NAME'
          value: topicName
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      linuxFxVersion: 'python|3.9'
    }
    httpsOnly: true
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

