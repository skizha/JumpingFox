# Test script for APIM rate limiting
# This script tests the rate limiting policies applied to your APIM-protected API

param(
    [string]$ApimGatewayUrl = "", # Will be populated after APIM setup
    [string]$SubscriptionKey = "", # Get this from APIM Developer Portal
    [int]$RequestCount = 150, # Number of requests to send (should exceed rate limit)
    [int]$DelayBetweenRequests = 100 # Delay in milliseconds
)

if ([string]::IsNullOrEmpty($ApimGatewayUrl)) {
    Write-Host "❌ Please provide the APIM Gateway URL" -ForegroundColor Red
    Write-Host "Example: .\test-apim-rate-limits.ps1 -ApimGatewayUrl 'https://your-apim.azure-api.net' -SubscriptionKey 'your-key'" -ForegroundColor Yellow
    exit 1
}

if ([string]::IsNullOrEmpty($SubscriptionKey)) {
    Write-Host "❌ Please provide a subscription key from APIM Developer Portal" -ForegroundColor Red
    Write-Host "Get subscription key from: https://your-apim.portal.azure-api.net/" -ForegroundColor Yellow
    exit 1
}

Write-Host "🧪 Testing APIM Rate Limiting" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Gateway URL: $ApimGatewayUrl" -ForegroundColor White
Write-Host "Subscription Key: $($SubscriptionKey.Substring(0, 8))..." -ForegroundColor White
Write-Host "Request Count: $RequestCount" -ForegroundColor White
Write-Host "Expected Rate Limit: 100 requests/minute" -ForegroundColor White
Write-Host ""

# Test endpoints
$endpoints = @(
    @{ Path = "/api/fox/jump"; Name = "Jump Endpoint"; ExpectedLimit = 100 },
    @{ Path = "/api/test/fast"; Name = "Fast Test Endpoint"; ExpectedLimit = 1000 },
    @{ Path = "/api/test/slow"; Name = "Slow Test Endpoint"; ExpectedLimit = 10 },
    @{ Path = "/api/jump/stats"; Name = "Analytics Endpoint"; ExpectedLimit = 30 }
)

foreach ($endpoint in $endpoints) {
    Write-Host "🎯 Testing: $($endpoint.Name)" -ForegroundColor Yellow
    Write-Host "Expected limit: $($endpoint.ExpectedLimit) requests/minute" -ForegroundColor Gray
    
    $successCount = 0
    $rateLimitCount = 0
    $errorCount = 0
    $startTime = Get-Date
    
    for ($i = 1; $i -le $RequestCount; $i++) {
        try {
            $headers = @{
                "Ocp-Apim-Subscription-Key" = $SubscriptionKey
                "X-Client-Id" = "test-client-$i"
            }
            
            $response = Invoke-WebRequest -Uri "$ApimGatewayUrl$($endpoint.Path)" -Headers $headers -ErrorAction Stop
            
            if ($response.StatusCode -eq 200) {
                $successCount++
                Write-Host "✅ Request $i`: Success" -ForegroundColor Green
            }
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 429) {
                $rateLimitCount++
                Write-Host "🛑 Request $i`: Rate Limited (429)" -ForegroundColor Red
                
                # Extract retry-after header if available
                $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                if ($retryAfter) {
                    Write-Host "   Retry-After: $retryAfter seconds" -ForegroundColor Gray
                }
            } else {
                $errorCount++
                Write-Host "❌ Request $i`: Error ($statusCode)" -ForegroundColor Red
            }
        }
        
        # Add delay between requests
        if ($DelayBetweenRequests -gt 0) {
            Start-Sleep -Milliseconds $DelayBetweenRequests
        }
        
        # Show progress every 10 requests
        if ($i % 10 -eq 0) {
            $elapsed = (Get-Date) - $startTime
            Write-Host "📊 Progress: $i/$RequestCount (Success: $successCount, Rate Limited: $rateLimitCount, Errors: $errorCount)" -ForegroundColor Cyan
        }
    }
    
    $totalTime = (Get-Date) - $startTime
    
    Write-Host ""
    Write-Host "📈 Results for $($endpoint.Name):" -ForegroundColor Cyan
    Write-Host "  ✅ Successful: $successCount" -ForegroundColor Green
    Write-Host "  🛑 Rate Limited: $rateLimitCount" -ForegroundColor Red
    Write-Host "  ❌ Errors: $errorCount" -ForegroundColor Red
    Write-Host "  ⏱️  Total Time: $($totalTime.TotalSeconds.ToString('F2')) seconds" -ForegroundColor White
    Write-Host "  📊 Rate: $((($successCount + $rateLimitCount) / $totalTime.TotalMinutes).ToString('F2')) requests/minute" -ForegroundColor White
    
    # Analysis
    if ($rateLimitCount -gt 0) {
        Write-Host "  ✅ Rate limiting is working correctly!" -ForegroundColor Green
        $effectiveLimit = $successCount
        if ($effectiveLimit -le $endpoint.ExpectedLimit + 5) { # Allow small variance
            Write-Host "  ✅ Rate limit appears to be enforced at ~$effectiveLimit requests/minute" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Rate limit seems higher than expected ($effectiveLimit vs $($endpoint.ExpectedLimit))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠️  No rate limiting detected - check APIM policy configuration" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    # Wait a bit before testing next endpoint to reset rate limits
    if ($endpoint -ne $endpoints[-1]) {
        Write-Host "⏱️  Waiting 65 seconds for rate limit window to reset..." -ForegroundColor Gray
        Start-Sleep 65
    }
}

Write-Host "🎉 Rate limiting test completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review the results above" -ForegroundColor White
Write-Host "  2. Adjust rate limiting policies in APIM if needed" -ForegroundColor White
Write-Host "  3. Test with different subscription keys" -ForegroundColor White
Write-Host "  4. Monitor APIM analytics in Azure Portal" -ForegroundColor White
