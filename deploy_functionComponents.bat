set resourceGroup=rg-2022-08-09

az deployment group create ^
  --name functionDeploy ^
  --resource-group %resourceGroup% ^
  --template-file functionContent.bicep ^
  --parameters storageAccountType=Standard_LRS