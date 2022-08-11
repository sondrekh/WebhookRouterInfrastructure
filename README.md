# WebhookRouterInfrastructure

For lokal deploy:
```
az group create --name rg-webhook --location northeurope
az deployment group create --resource-group rg-webhook --template-file main.bicep
```

For D365-deploy: 
- Opprett infrastrukturen i Azure (lokalt først, deretter pipeline)
- Publiser Azure Function med ruting-funksjonalitet (lokalt -> pipeline)
- Hent ut funksjons-url og -key fra ruting-funksjon for bruk i D365
- Opprett en egen solution for webhooks for meldingssending ut av D365. Kan kjøre egen solution for mest mulig separat deply. Lar seg gjøre ettersom webhooks av natur ikke har noen avhengigheter inn i Dynamics. 
- Registrer et endepunkt med url fra punktet over, legg til nøkkelen under "webhook key"

