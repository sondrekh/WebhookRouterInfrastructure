set resourceGroup=rg-2022-08-09

az deployment sub create ^
    --location northeurope^
    --template-file resourceGroup.bicep ^
    --parameters ^
        name=%resourceGroup%