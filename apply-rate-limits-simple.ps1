# Apply Updated Rate Limit Policies to APIM - Simple Approach
# This script applies the new rate limits using a simpler method

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

# Method 1: Apply overall policy using PowerShell directly
Write-Host "📋 Applying Overall API Policy (10,000 req/min)..." -ForegroundColor Yellow

$overallPolicy = @"
<policies>
    <inbound>
        <base />
        <rate-limit-by-subscription calls="10000" renewal-period="60" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
"@

# Save policy to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
$overallPolicy | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline

try {
    # Apply overall policy
    az rest --method put `
        --url "https://management.azure.com/subscriptions/$($config.azure.subscriptionId)/resourceGroups/$($config.azure.resourceGroup)/providers/Microsoft.ApiManagement/service/$($config.apim.name)/apis/$($config.apim.apiName)/policies/policy?api-version=2021-08-01" `
        --body "@$tempFile" `
        --headers "Content-Type=application/vnd.ms-azure-apim.policy+xml"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Overall API policy applied successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to apply overall API policy" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error applying overall policy: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""

# Method 2: Apply Create Fox operation policy
Write-Host "📋 Applying Create Fox Operation Policy (5 req/min per IP)..." -ForegroundColor Yellow

$createFoxPolicy = @"
<policies>
    <inbound>
        <base />
        <rate-limit-by-key calls="5" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
"@

# Save policy to temp file
$tempFile2 = [System.IO.Path]::GetTempFileName()
$createFoxPolicy | Out-File -FilePath $tempFile2 -Encoding UTF8 -NoNewline

try {
    # Apply Create Fox operation policy
    az rest --method put `
        --url "https://management.azure.com/subscriptions/$($config.azure.subscriptionId)/resourceGroups/$($config.azure.resourceGroup)/providers/Microsoft.ApiManagement/service/$($config.apim.name)/apis/$($config.apim.apiName)/operations/post-api-fox/policies/policy?api-version=2021-08-01" `
        --body "@$tempFile2" `
        --headers "Content-Type=application/vnd.ms-azure-apim.policy+xml"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Create Fox operation policy applied successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to apply Create Fox operation policy" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Error applying Create Fox policy: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Remove-Item $tempFile2 -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "🎉 Rate Limit Policy Update Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Updated Rate Limits Summary:" -ForegroundColor Cyan
Write-Host "  🌐 Overall API: 10,000 requests/minute (subscription-based)" -ForegroundColor White
Write-Host "  🦊 Create Fox: 5 requests/minute (IP-based)" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Test the new limits:" -ForegroundColor Yellow
Write-Host "  .\test-create-fox-rate-limit.ps1" -ForegroundColor White
Write-Host "  .\test-rate-limit.ps1" -ForegroundColor White
Write-Host ""
Write-Host "⏱️  Note: It may take 1-2 minutes for policy changes to take effect" -ForegroundColor Gray
