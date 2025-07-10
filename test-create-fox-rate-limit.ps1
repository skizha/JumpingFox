# Test Create Fox Rate Limiting
# Tests the IP-based rate limit of 5 requests per minute for Create Fox API

param(
    [string]$ConfigPath = "config.json",
    [int]$TestRequests = 8
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

Write-Host "🧪 Testing Create Fox Rate Limiting" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "API URL: $($config.apim.gatewayUrl)/api/api/Fox" -ForegroundColor White
Write-Host "Rate Limit: 5 requests/minute (IP-based)" -ForegroundColor White
Write-Host "Test Requests: $TestRequests" -ForegroundColor White
Write-Host ""

$successCount = 0
$rateLimitCount = 0
$errorCount = 0

for ($i = 1; $i -le $TestRequests; $i++) {
    Write-Host "Request $i of $TestRequests`: " -NoNewline
    
    # Create a test fox with unique name
    $foxData = @{
        name = "TestFox$i"
        color = @("Red", "Silver", "Golden", "White", "Black")[(Get-Random -Maximum 5)]
        jumpHeight = Get-Random -Minimum 1 -Maximum 10
        isActive = $true
    } | ConvertTo-Json
    
    try {
        $headers = @{
            "Ocp-Apim-Subscription-Key" = $config.apim.subscriptionKey
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-WebRequest -Uri "$($config.apim.gatewayUrl)/api/api/Fox" `
            -Method POST `
            -Headers $headers `
            -Body $foxData `
            -ErrorAction Stop
        
        if ($response.StatusCode -eq 201) {
            $successCount++
            Write-Host "✅ Success (Created)" -ForegroundColor Green
            
            # Parse response to show created fox
            $responseData = $response.Content | ConvertFrom-Json
            Write-Host "    🦊 Created: $($responseData.data.name) (ID: $($responseData.data.id))" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Unexpected response: $($response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 429) {
            $rateLimitCount++
            Write-Host "🛑 Rate Limited (429)" -ForegroundColor Red
            
            # Try to get retry-after header
            try {
                $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                if ($retryAfter) {
                    Write-Host "    ⏱️  Retry-After: $retryAfter seconds" -ForegroundColor Gray
                }
            } catch {
                # Ignore header parsing errors
            }
        } else {
            $errorCount++
            Write-Host "❌ Error ($statusCode)" -ForegroundColor Red
            if ($_.Exception.Message) {
                Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
            }
        }
    }
    
    # Small delay between requests
    if ($i -lt $TestRequests) {
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ""
Write-Host "📊 Test Results Summary" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host "Total Requests: $TestRequests" -ForegroundColor White
Write-Host "Successful (201): $successCount" -ForegroundColor Green
Write-Host "Rate Limited (429): $rateLimitCount" -ForegroundColor Red
Write-Host "Other Errors: $errorCount" -ForegroundColor Red

Write-Host ""
if ($rateLimitCount -gt 0 -and $successCount -le 6) {
    Write-Host "🎉 Rate limiting is working correctly!" -ForegroundColor Green
    Write-Host "   Expected: ~5 successful requests, then rate limiting" -ForegroundColor Gray
    Write-Host "   Actual: $successCount successful, $rateLimitCount rate limited" -ForegroundColor Gray
} elseif ($rateLimitCount -eq 0) {
    Write-Host "⚠️  No rate limiting detected" -ForegroundColor Yellow
    Write-Host "   Check if the Create Fox policy is properly applied" -ForegroundColor Gray
} else {
    Write-Host "ℹ️  Rate limiting detected but might need adjustment" -ForegroundColor Blue
    Write-Host "   Got $successCount successful requests before rate limiting" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait 1 minute for rate limit to reset" -ForegroundColor White
Write-Host "  2. Test from different IP to verify IP-based limiting" -ForegroundColor White
Write-Host "  3. Test other endpoints to verify overall 10k limit" -ForegroundColor White
