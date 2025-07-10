# Apply Updated Rate Limit Policies to APIM
# This script applies the new rate limits:
# - Overall: 10,000 requests per minute per subscription
# - Create Fox: 5 requests per minute per IP address

param(
    [string]$ConfigPath = "config.json"
)

# Load configuration
try {
    . "$PSScriptRoot\Config.ps1"
    $config = Get-JumpingFoxConfig -ConfigPath $ConfigPath
    Write-Host "✅ Configuration loaded from $ConfigPath" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to load configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Applying Updated Rate Limit Policies" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "APIM Service: $($config.apim.name)" -ForegroundColor White
Write-Host "API: $($config.apim.apiName)" -ForegroundColor White
Write-Host ""

# Apply overall API policy (10,000 requests per minute)
Write-Host "📋 Applying Overall API Policy (10,000 req/min)..." -ForegroundColor Yellow

try {
    $overallPolicyPath = "$PSScriptRoot\apim-policy-overall.xml"
    if (-not (Test-Path $overallPolicyPath)) {
        Write-Host "❌ Policy file not found: $overallPolicyPath" -ForegroundColor Red
        exit 1
    }

    $result = az rest --method put `
        --url "https://management.azure.com/subscriptions/$($config.azure.subscriptionId)/resourceGroups/$($config.azure.resourceGroup)/providers/Microsoft.ApiManagement/service/$($config.apim.name)/apis/$($config.apim.apiName)/policies/policy?api-version=2021-08-01" `
        --body "@$overallPolicyPath" `
        --headers "Content-Type=application/vnd.ms-azure-apim.policy+xml"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Overall API policy applied successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to apply overall API policy" -ForegroundColor Red
        Write-Host "Error: $result" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error applying overall policy: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Apply Create Fox operation policy (5 requests per minute per IP)
Write-Host "📋 Applying Create Fox Operation Policy (5 req/min per IP)..." -ForegroundColor Yellow

try {
    $createFoxPolicyPath = "$PSScriptRoot\apim-policy-create-fox.xml"
    if (-not (Test-Path $createFoxPolicyPath)) {
        Write-Host "❌ Policy file not found: $createFoxPolicyPath" -ForegroundColor Red
        exit 1
    }

    $result = az rest --method put `
        --url "https://management.azure.com/subscriptions/$($config.azure.subscriptionId)/resourceGroups/$($config.azure.resourceGroup)/providers/Microsoft.ApiManagement/service/$($config.apim.name)/apis/$($config.apim.apiName)/operations/post-api-fox/policies/policy?api-version=2021-08-01" `
        --body "@$createFoxPolicyPath" `
        --headers "Content-Type=application/vnd.ms-azure-apim.policy+xml"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Create Fox operation policy applied successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to apply Create Fox operation policy" -ForegroundColor Red
        Write-Host "Error: $result" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error applying Create Fox policy: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Rate Limit Policy Update Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Updated Rate Limits Summary:" -ForegroundColor Cyan
Write-Host "  🌐 Overall API: 10,000 requests/minute (subscription-based)" -ForegroundColor White
Write-Host "  🦊 Create Fox: 5 requests/minute (IP-based)" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Test the new limits:" -ForegroundColor Yellow
Write-Host "  1. Test overall limits with any endpoint" -ForegroundColor White
Write-Host "  2. Test Create Fox with: POST /api/api/Fox" -ForegroundColor White
Write-Host "  3. Use different IP addresses to test IP-based limiting" -ForegroundColor White
Write-Host ""
Write-Host "⏱️  Note: It may take 1-2 minutes for policy changes to take effect" -ForegroundColor Gray
