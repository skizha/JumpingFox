# JumpingFox API Rate Limit Testing Script
# This script helps test various rate limiting scenarios with the JumpingFox API

param(
    [Parameter(Mandatory=$true)]
    [string]$BaseUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionKey = "",
    
    [Parameter(Mandatory=$false)]
    [int]$TestDuration = 60,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId = "test-client-1"
)

# Ensure the base URL doesn't end with a slash
$BaseUrl = $BaseUrl.TrimEnd('/')

Write-Host "🦊 JumpingFox API Rate Limit Testing" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host "Test Duration: $TestDuration seconds" -ForegroundColor Yellow
Write-Host "Client ID: $ClientId" -ForegroundColor Yellow
Write-Host "=" * 50

# Common headers
$headers = @{
    "Content-Type" = "application/json"
    "X-Client-Id" = $ClientId
}

if ($SubscriptionKey -ne "") {
    $headers["Ocp-Apim-Subscription-Key"] = $SubscriptionKey
    Write-Host "Using Subscription Key: $($SubscriptionKey.Substring(0,8))..." -ForegroundColor Yellow
}

# Function to make HTTP requests and handle rate limiting
function Test-Endpoint {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null,
        [int]$RequestCount = 10,
        [int]$DelayMs = 100
    )
    
    Write-Host "`n🧪 Testing: $Method $Endpoint" -ForegroundColor Cyan
    Write-Host "Requests: $RequestCount, Delay: ${DelayMs}ms" -ForegroundColor Gray
    
    $successCount = 0
    $rateLimitCount = 0
    $errorCount = 0
    $totalTime = 0
    
    for ($i = 1; $i -le $RequestCount; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $requestParams = @{
                Uri = "$BaseUrl$Endpoint"
                Method = $Method
                Headers = $headers
                TimeoutSec = 30
            }
            
            if ($Body -ne $null) {
                $requestParams.Body = ($Body | ConvertTo-Json)
            }
            
            $response = Invoke-RestMethod @requestParams
            $stopwatch.Stop()
            $totalTime += $stopwatch.ElapsedMilliseconds
            
            $successCount++
            Write-Host "  ✅ Request $i succeeded (${stopwatch.ElapsedMilliseconds}ms)" -ForegroundColor Green
        }
        catch {
            $stopwatch.Stop()
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            if ($statusCode -eq 429) {
                $rateLimitCount++
                Write-Host "  ⏱️  Request $i rate limited (429)" -ForegroundColor Yellow
            }
            else {
                $errorCount++
                Write-Host "  ❌ Request $i failed ($statusCode): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        if ($i -lt $RequestCount) {
            Start-Sleep -Milliseconds $DelayMs
        }
    }
    
    $avgTime = if ($successCount -gt 0) { [math]::Round($totalTime / $successCount, 2) } else { 0 }
    
    Write-Host "  📊 Results: $successCount success, $rateLimitCount rate limited, $errorCount errors" -ForegroundColor Magenta
    Write-Host "  📊 Average response time: ${avgTime}ms" -ForegroundColor Magenta
    
    return @{
        Success = $successCount
        RateLimited = $rateLimitCount
        Errors = $errorCount
        AverageTime = $avgTime
    }
}

# Test 1: Fast endpoint with high frequency
Write-Host "`n🚀 Test 1: Fast Endpoint (High Frequency)" -ForegroundColor Blue
$result1 = Test-Endpoint -Endpoint "/api/test/fast" -RequestCount 50 -DelayMs 50

# Test 2: Slow endpoint with moderate frequency
Write-Host "`n🐌 Test 2: Slow Endpoint (Moderate Frequency)" -ForegroundColor Blue
$result2 = Test-Endpoint -Endpoint "/api/test/slow" -RequestCount 10 -DelayMs 500

# Test 3: Memory intensive endpoint
Write-Host "`n🧠 Test 3: Memory Intensive Endpoint" -ForegroundColor Blue
$result3 = Test-Endpoint -Endpoint "/api/test/memory-intensive" -RequestCount 15 -DelayMs 200

# Test 4: CRUD operations on Fox API
Write-Host "`n🦊 Test 4: Fox CRUD Operations" -ForegroundColor Blue

# GET requests
$result4a = Test-Endpoint -Endpoint "/api/fox" -RequestCount 20 -DelayMs 100

# POST requests
$newFox = @{
    name = "Test Fox $(Get-Random)"
    color = "Orange"
    jumpHeight = 5
    isActive = $true
}
$result4b = Test-Endpoint -Endpoint "/api/fox" -Method "POST" -Body $newFox -RequestCount 10 -DelayMs 200

# Test 5: Batch operations
Write-Host "`n📦 Test 5: Batch Operations" -ForegroundColor Blue
$batchRequest = @{
    clientId = $ClientId
    requestCount = 25
    testType = "rate-limit-batch-test"
}
$result5 = Test-Endpoint -Endpoint "/api/test/batch" -Method "POST" -Body $batchRequest -RequestCount 8 -DelayMs 300

# Test 6: Analytics endpoint
Write-Host "`n📈 Test 6: Analytics Endpoint" -ForegroundColor Blue
$result6 = Test-Endpoint -Endpoint "/api/jump/stats" -RequestCount 15 -DelayMs 150

# Test 7: Load testing endpoint
Write-Host "`n⚡ Test 7: Load Testing" -ForegroundColor Blue
$result7 = Test-Endpoint -Endpoint "/api/test/load?operations=20" -Method "POST" -RequestCount 5 -DelayMs 1000

# Get final metrics
Write-Host "`n📊 Getting Final Metrics" -ForegroundColor Blue
try {
    $metrics = Invoke-RestMethod -Uri "$BaseUrl/api/test/metrics" -Headers $headers
    Write-Host "Final API Metrics:" -ForegroundColor Green
    Write-Host "  Total Requests: $($metrics.data.totalRequests)" -ForegroundColor White
    Write-Host "  Last Request: $($metrics.data.lastRequestTime)" -ForegroundColor White
    
    if ($metrics.data.endpointCalls) {
        Write-Host "  Endpoint Breakdown:" -ForegroundColor White
        $metrics.data.endpointCalls.PSObject.Properties | ForEach-Object {
            Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "Could not retrieve metrics: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n" + "=" * 50 -ForegroundColor Green
Write-Host "📋 TEST SUMMARY" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

$allResults = @($result1, $result2, $result3, $result4a, $result4b, $result5, $result6, $result7)
$totalSuccess = ($allResults | Measure-Object -Property Success -Sum).Sum
$totalRateLimited = ($allResults | Measure-Object -Property RateLimited -Sum).Sum
$totalErrors = ($allResults | Measure-Object -Property Errors -Sum).Sum
$totalRequests = $totalSuccess + $totalRateLimited + $totalErrors

Write-Host "Total Requests Sent: $totalRequests" -ForegroundColor White
Write-Host "Successful Requests: $totalSuccess ($([math]::Round($totalSuccess/$totalRequests*100,1))%)" -ForegroundColor Green
Write-Host "Rate Limited: $totalRateLimited ($([math]::Round($totalRateLimited/$totalRequests*100,1))%)" -ForegroundColor Yellow
Write-Host "Errors: $totalErrors ($([math]::Round($totalErrors/$totalRequests*100,1))%)" -ForegroundColor Red

if ($totalRateLimited -gt 0) {
    Write-Host "`n✅ Rate limiting is working! Found $totalRateLimited rate-limited responses." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  No rate limiting detected. Check your APIM policies." -ForegroundColor Yellow
}

Write-Host "`n🔗 Useful Links:" -ForegroundColor Cyan
Write-Host "  Swagger UI: $BaseUrl/" -ForegroundColor White
Write-Host "  Health Check: $BaseUrl/health" -ForegroundColor White
Write-Host "  Reset Metrics: POST $BaseUrl/api/test/metrics/reset" -ForegroundColor White

Write-Host "`nTesting completed! 🎉" -ForegroundColor Green
