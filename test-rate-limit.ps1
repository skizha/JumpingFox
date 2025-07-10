# Test Rate Limiting on APIM
param(
    [string]$ApiUrl,
    [string]$SubscriptionKey,
    [int]$NumRequests,
    [int]$DelaySeconds,
    [string]$ConfigPath = "config.json"
)

# Load configuration
. .\Config.ps1

try {
    $config = Get-JumpingFoxConfig -ConfigPath $ConfigPath
    
    # Use provided parameters or fall back to config values
    if (-not $ApiUrl) { $ApiUrl = "$($config.apim.gatewayUrl)/api/health" }
    if (-not $SubscriptionKey) { $SubscriptionKey = $config.apim.subscriptionKey }
    if (-not $NumRequests) { $NumRequests = $config.testing.testRequests }
    if (-not $DelaySeconds) { $DelaySeconds = $config.testing.delaySeconds }
}
catch {
    Write-Host "❌ Failed to load configuration. Using default values." -ForegroundColor Red
    Write-Host "   Run Initialize-JumpingFoxConfig to create config.json" -ForegroundColor Yellow
    
    # Fallback to original hardcoded values if config fails
    if (-not $ApiUrl) { $ApiUrl = "https://jumpingfox-apim-20250709.azure-api.net/api/health" }
    if (-not $SubscriptionKey) { $SubscriptionKey = "9612af95b175494a90156d864d8c6b65" }
    if (-not $NumRequests) { $NumRequests = 8 }
    if (-not $DelaySeconds) { $DelaySeconds = 1 }
}

Write-Host "🧪 Testing APIM Rate Limiting" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "API URL: $ApiUrl" -ForegroundColor White
Write-Host "Requests: $NumRequests" -ForegroundColor White
Write-Host "Delay: $DelaySeconds seconds" -ForegroundColor White
Write-Host "Expected: First 5 requests should succeed, then rate limit kicks in" -ForegroundColor Yellow
Write-Host ""

$headers = @{ 'Ocp-Apim-Subscription-Key' = $SubscriptionKey }
$successCount = 0
$rateLimitCount = 0

for ($i = 1; $i -le $NumRequests; $i++) {
    Write-Host "Request $i of ${NumRequests}:" -ForegroundColor Yellow -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $ApiUrl -Headers $headers -ErrorAction Stop
        $statusCode = $response.StatusCode
        
        if ($statusCode -eq 200) {
            $successCount++
            Write-Host " ✅ HTTP $statusCode - Success" -ForegroundColor Green
            
            # Try to get rate limit headers
            $rateLimitHeaders = @()
            if ($response.Headers.'X-RateLimit-Limit') {
                $rateLimitHeaders += "Limit: $($response.Headers.'X-RateLimit-Limit')"
            }
            if ($response.Headers.'X-RateLimit-Remaining') {
                $rateLimitHeaders += "Remaining: $($response.Headers.'X-RateLimit-Remaining')"
            }
            if ($response.Headers.'X-Correlation-Id') {
                $rateLimitHeaders += "Correlation: $($response.Headers.'X-Correlation-Id'[0..7] -join '')"
            }
            
            if ($rateLimitHeaders) {
                Write-Host "    📊 Headers: $($rateLimitHeaders -join ', ')" -ForegroundColor Gray
            }
            
            # Parse response if it's JSON
            try {
                $jsonResponse = $response.Content | ConvertFrom-Json
                if ($jsonResponse.status) {
                    Write-Host "    📋 Status: $($jsonResponse.status)" -ForegroundColor Gray
                }
            } catch {
                # Not JSON, that's fine
            }
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $reasonPhrase = $_.Exception.Response.ReasonPhrase
        
        if ($statusCode -eq 429) {
            $rateLimitCount++
            Write-Host " 🚫 HTTP $statusCode - Rate Limited!" -ForegroundColor Red
            
            # Try to get retry-after header
            if ($_.Exception.Response.Headers.'Retry-After') {
                Write-Host "    ⏰ Retry After: $($_.Exception.Response.Headers.'Retry-After') seconds" -ForegroundColor Yellow
            }
        } else {
            Write-Host " ❌ HTTP $statusCode - $reasonPhrase" -ForegroundColor Red
        }
        
        # Try to get error response body
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            if ($errorBody) {
                $errorJson = $errorBody | ConvertFrom-Json
                if ($errorJson.message) {
                    Write-Host "    📝 Error: $($errorJson.message)" -ForegroundColor Red
                }
            }
        } catch {
            # Error reading error response, that's fine
        }
    }
    
    # Wait before next request (except for the last one)
    if ($i -lt $NumRequests) {
        Start-Sleep -Seconds $DelaySeconds
    }
}

# Summary
Write-Host ""
Write-Host "📊 Test Results Summary" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Total Requests: $NumRequests" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Rate Limited: $rateLimitCount" -ForegroundColor Red
Write-Host "Other Errors: $($NumRequests - $successCount - $rateLimitCount)" -ForegroundColor Yellow

Write-Host ""
if ($rateLimitCount -gt 0) {
    Write-Host "🎉 Rate limiting is working correctly!" -ForegroundColor Green
    Write-Host "   The first few requests succeeded, then APIM started rate limiting" -ForegroundColor White
} else {
    Write-Host "⚠️  Rate limiting may not be working as expected" -ForegroundColor Yellow
    Write-Host "   All requests succeeded - check the rate limit configuration" -ForegroundColor White
}

Write-Host ""
Write-Host "🔄 To test again after rate limit resets, wait 1 minute and rerun this script" -ForegroundColor Cyan
