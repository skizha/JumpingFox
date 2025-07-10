# Alternative deployment script using Azure CLI commands
# This bypasses ARM template issues and creates resources directly

# Variables - Update these with your values
$resourceGroup = "rg-jumpingfox-new"  # Update with your preferred resource group name
$location = "East US"  # Or change to your preferred region
$webAppName = "jumpingfox-api-$(Get-Date -Format 'yyyyMMddHHmm')"
$planName = "$webAppName-plan"

# Check if logged into Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show --query "user.name" --output tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged into Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in as: $account" -ForegroundColor Green

# Create resource group if it doesn't exist
Write-Host "Creating resource group: $resourceGroup in $location" -ForegroundColor Yellow
az group create --name $resourceGroup --location $location

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create resource group" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Resource group created/verified" -ForegroundColor Green

# Create App Service Plan
Write-Host "Creating App Service Plan: $planName" -ForegroundColor Yellow
az appservice plan create --name $planName --resource-group $resourceGroup --location $location --sku S1 --is-linux

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create App Service Plan" -ForegroundColor Red
    exit 1
}
Write-Host "✅ App Service Plan created" -ForegroundColor Green

# Create Web App
Write-Host "Creating Web App: $webAppName" -ForegroundColor Yellow
az webapp create --name $webAppName --resource-group $resourceGroup --plan $planName --runtime "DOTNETCORE:8.0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create Web App" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Web App created successfully" -ForegroundColor Green

# Configure app settings
Write-Host "Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set --name $webAppName --resource-group $resourceGroup --settings ASPNETCORE_ENVIRONMENT=Production

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to configure app settings" -ForegroundColor Red
    exit 1
}
Write-Host "✅ App settings configured" -ForegroundColor Green

# Get the web app URL
Write-Host "Getting Web App URL..." -ForegroundColor Yellow
$webAppUrl = az webapp show --name $webAppName --resource-group $resourceGroup --query "defaultHostName" --output tsv
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Web App Details:" -ForegroundColor Cyan
Write-Host "  📍 Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "  🏷️  App Name: $webAppName" -ForegroundColor White
Write-Host "  🌍 Region: $location" -ForegroundColor White
Write-Host "  📋 Plan: $planName" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Important URLs:" -ForegroundColor Cyan
Write-Host "  🏠 API Base URL: https://$webAppUrl" -ForegroundColor Green
Write-Host "  📚 Swagger UI: https://$webAppUrl/" -ForegroundColor Green
Write-Host "  ❤️  Health Check: https://$webAppUrl/health" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy your code: az webapp deployment source config-zip --src ./publish.zip --name $webAppName --resource-group $resourceGroup"
Write-Host "  2. Visit the Swagger UI to test endpoints"
Write-Host "  3. Set up APIM and import this API"
Write-Host "  4. Configure rate limiting policies"
Write-Host "  5. Test rate limits using: .\test-rate-limits.ps1 -BaseUrl https://$webAppUrl"
