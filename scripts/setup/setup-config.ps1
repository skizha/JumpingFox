# JumpingFox Configuration Setup
# This script helps you set up the configuration file for the first time

Write-Host "🔧 JumpingFox Configuration Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Load configuration helper
. "$PSScriptRoot\..\..\Config.ps1"

# Check if config already exists
if (Test-Path "$PSScriptRoot\..\..\config.json") {
    Write-Host "⚠️  Configuration file already exists." -ForegroundColor Yellow
    $choice = Read-Host "Do you want to (O)verwrite, (V)iew current, or (E)xit? [O/V/E]"
    
    switch ($choice.ToUpper()) {
        "V" {
            Write-Host "📋 Current configuration:" -ForegroundColor Cyan
            $currentConfig = Get-Content "config.json" -Raw | ConvertFrom-Json
            $currentConfig | ConvertTo-Json -Depth 3
            exit 0
        }
        "E" {
            Write-Host "❌ Setup cancelled." -ForegroundColor Red
            exit 0
        }
        default {
            Write-Host "📝 Overwriting existing configuration..." -ForegroundColor Yellow
        }
    }
}

# Initialize from template
Initialize-JumpingFoxConfig

# Interactive setup
Write-Host ""
Write-Host "📝 Let's configure your JumpingFox deployment..." -ForegroundColor Yellow
Write-Host ""

# Get Azure details
Write-Host "🔷 Azure Configuration:" -ForegroundColor Cyan
$subscriptionId = Read-Host "Enter your Azure Subscription ID"
$resourceGroup = Read-Host "Enter Resource Group name [default: rg-jumpingfox-aks]"
if ([string]::IsNullOrWhiteSpace($resourceGroup)) { $resourceGroup = "rg-jumpingfox-aks" }

$location = Read-Host "Enter Azure Region [default: East US]"
if ([string]::IsNullOrWhiteSpace($location)) { $location = "East US" }

$publisherEmail = Read-Host "Enter your email address"
$publisherName = Read-Host "Enter your name or organization"

Write-Host ""
Write-Host "🌐 APIM Configuration:" -ForegroundColor Cyan
$apimName = Read-Host "Enter APIM instance name [default: jumpingfox-apim-$(Get-Date -Format 'yyyyMMdd')]"
if ([string]::IsNullOrWhiteSpace($apimName)) { $apimName = "jumpingfox-apim-$(Get-Date -Format 'yyyyMMdd')" }

$gatewayUrl = Read-Host "Enter APIM Gateway URL (if known) [leave blank for auto-detect]"
$subscriptionKey = Read-Host "Enter APIM Subscription Key (if known) [leave blank for auto-detect]"

Write-Host ""
Write-Host "🚢 AKS Configuration:" -ForegroundColor Cyan
$clusterName = Read-Host "Enter AKS cluster name [default: jumpingfox-aks]"
if ([string]::IsNullOrWhiteSpace($clusterName)) { $clusterName = "jumpingfox-aks" }

$backendUrl = Read-Host "Enter AKS backend URL (if known) [leave blank for auto-detect]"
$containerRegistry = Read-Host "Enter ACR name [default: jumpingfoxacr]"
if ([string]::IsNullOrWhiteSpace($containerRegistry)) { $containerRegistry = "jumpingfoxacr" }

# Create configuration object
$config = @{
    azure = @{
        subscriptionId = $subscriptionId
        resourceGroup = $resourceGroup
        location = $location
        publisherEmail = $publisherEmail
        publisherName = $publisherName
    }
    apim = @{
        name = $apimName
        gatewayUrl = if ($gatewayUrl) { $gatewayUrl } else { "https://$apimName.azure-api.net" }
        subscriptionKey = if ($subscriptionKey) { $subscriptionKey } else { "your-subscription-key-here" }
        apiName = "jumpingfox-api"
    }
    aks = @{
        clusterName = $clusterName
        backendUrl = if ($backendUrl) { $backendUrl } else { "http://your-aks-ip-address" }
        containerRegistry = $containerRegistry
    }
    testing = @{
        defaultRateLimit = 10
        testRequests = 8
        delaySeconds = 1
    }
}

# Save configuration
$config | ConvertTo-Json -Depth 3 | Out-File "config.json" -Encoding UTF8

Write-Host ""
Write-Host "✅ Configuration saved to config.json" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Review and edit config.json if needed" -ForegroundColor White
Write-Host "2. Run .\deploy-aks.ps1 to deploy to AKS" -ForegroundColor White
Write-Host "3. Run .\setup-apim.ps1 to set up API Management" -ForegroundColor White
Write-Host "4. Run .\get-apim-key.ps1 to get subscription keys" -ForegroundColor White
Write-Host "5. Run .\test-rate-limit.ps1 to test rate limiting" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Important: Never commit config.json to version control!" -ForegroundColor Red
Write-Host "   It contains sensitive information like subscription keys." -ForegroundColor Red
