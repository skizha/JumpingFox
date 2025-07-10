# Apply Fixed APIM Policies
# This script applies the corrected APIM policies with proper rate-limit-by-key syntax

# Load configuration
. .\Config.ps1

if (-not $config) {
    Write-Error "Failed to load configuration. Make sure config.json exists and is valid."
    exit 1
}

Write-Host "Applying Fixed APIM Policies..." -ForegroundColor Green

# Apply overall API policy
Write-Host "Applying overall API policy..."
try {
    az apim api policy update `
        --resource-group $config.azureResourceGroup `
        --service-name $config.apimServiceName `
        --api-id $config.apimApiId `
        --policy-content (Get-Content "apim-policy-overall.xml" -Raw)
    
    Write-Host "Overall API policy applied successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to apply overall API policy: $_"
}

# Apply Create Fox operation policy
Write-Host "Applying Create Fox operation policy..."
try {
    az apim api operation policy apply `
        --resource-group $config.azureResourceGroup `
        --service-name $config.apimServiceName `
        --api-id $config.apimApiId `
        --operation-id "CreateFox" `
        --policy-content (Get-Content "apim-policy-create-fox.xml" -Raw)
    
    Write-Host "Create Fox operation policy applied successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to apply Create Fox operation policy: $_"
}

Write-Host "Policy application completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Rate Limits Applied:" -ForegroundColor Yellow
Write-Host "- Overall API: 10,000 requests per minute" -ForegroundColor White
Write-Host "- Create Fox (POST /api/Fox): 5 requests per minute per IP" -ForegroundColor White
Write-Host ""
Write-Host "You can now test the rate limits with:" -ForegroundColor Cyan
Write-Host "  .\test-apim-rate-limits.ps1" -ForegroundColor White
Write-Host "  .\test-create-fox-rate-limit.ps1" -ForegroundColor White
