set resourceGroup=rg-webhook

@REM az group create --name rg-webhook --location northeurope
az deployment group create ^
  --name functionDeploy ^
  --resource-group %resourceGroup% ^
  --template-file main.bicep ^
  --parameters storageAccountType=Standard_LRS