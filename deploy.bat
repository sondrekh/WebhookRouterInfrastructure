set resourceGroupName=rg-2022-08-09
set storageName=stg20220809
set location=northeurope
set serviceName=appservice20220809

az deployment sub create ^
    --location %location% ^
    --template-file main.bicep ^
    --parameters ^
        rgName=%resourceGroupName% ^
        storageName=%storageName% ^
        serviceName=%serviceName%
