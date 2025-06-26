# Azure CLI deployment script for JumpingFox API
# Make sure you're logged in: az login
# Set your subscription: az account set --subscription "your-subscription-id"

# Variables - Update these with your values
$resourceGroup = "rg-jumpingfox"
$location = "East US"
$webAppName = "jumpingfox-api-$(Get-Date -Format 'yyyyMMddHHmm')"
$containerRegistry = "your-acr-name"

# Create resource group if it doesn't exist
Write-Host "Creating resource group: $resourceGroup"
az group create --name $resourceGroup --location $location

# Deploy the ARM template
Write-Host "Deploying Azure Web App..."
az deployment group create `
  --resource-group $resourceGroup `
  --template-file azure-deploy.json `
  --parameters webAppName=$webAppName sku="B1"

# Get the web app URL
$webAppUrl = az webapp show --name $webAppName --resource-group $resourceGroup --query "defaultHostName" --output tsv
Write-Host "Web App URL: https://$webAppUrl"

# Optional: Deploy from local source (if you want to deploy directly)
# Uncomment the following lines if you want to deploy the source code directly
# Write-Host "Deploying source code..."
# az webapp deployment source config-zip `
#   --resource-group $resourceGroup `
#   --name $webAppName `
#   --src "jumpingfox.zip"

Write-Host "Deployment completed!"
Write-Host "API Base URL: https://$webAppUrl"
Write-Host "Swagger UI: https://$webAppUrl/swagger"
Write-Host "Health Check: https://$webAppUrl/health"
