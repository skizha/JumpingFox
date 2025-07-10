# Get APIM Subscription Key and Test API
param(
    [string]$ResourceGroup = "rg-jumpingfox-aks",
    [string]$ApimName = "jumpingfox-apim-$(Get-Date -Format 'yyyyMMdd')",
    [string]$ApiName = "jumpingfox-api"
)

Write-Host "🔑 Getting APIM Subscription Key for Testing" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check if logged into Azure
$account = az account show --query "user.name" --output tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged into Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in as: $account" -ForegroundColor Green

# Get APIM details
Write-Host ""
Write-Host "📋 Getting APIM details..." -ForegroundColor Yellow
$apimDetails = az apim show --name $ApimName --resource-group $ResourceGroup --output json 2>$null | ConvertFrom-Json

if (-not $apimDetails) {
    Write-Host "❌ APIM instance '$ApimName' not found in resource group '$ResourceGroup'" -ForegroundColor Red
    Write-Host "   Available APIM instances:" -ForegroundColor Gray
    az apim list --resource-group $ResourceGroup --query "[].{Name:name, Status:provisioningState}" --output table
    exit 1
}

$gatewayUrl = $apimDetails.gatewayUrl
Write-Host "✅ Found APIM: $gatewayUrl" -ForegroundColor Green

# Get built-in subscription key
Write-Host ""
Write-Host "🔑 Getting built-in subscription key..." -ForegroundColor Yellow

# List all subscriptions first
Write-Host "Listing available subscriptions..." -ForegroundColor Gray
$subscriptions = az apim subscription list `
    --resource-group $ResourceGroup `
    --service-name $ApimName `
    --output json 2>$null | ConvertFrom-Json

if ($subscriptions -and $subscriptions.Count -gt 0) {
    # Use the first available subscription
    $subscription = $subscriptions[0]
    $subscriptionKey = $subscription.primaryKey
    Write-Host "✅ Found existing subscription: $($subscription.displayName)" -ForegroundColor Green
} else {
    # Try to get the master/built-in subscription with correct command
    Write-Host "Getting built-in subscription..." -ForegroundColor Gray
    
    try {
        # Use the correct CLI command for APIM subscriptions
        $masterSub = az rest `
            --method GET `
            --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroup/providers/Microsoft.ApiManagement/service/$ApimName/subscriptions/master?api-version=2021-08-01" `
            --output json | ConvertFrom-Json
        
        if ($masterSub) {
            $subscriptionKey = $masterSub.properties.primaryKey
            Write-Host "✅ Found built-in subscription key!" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Could not get built-in subscription, trying alternative method..." -ForegroundColor Yellow
        
        # Alternative: Create a test subscription
        $testSubId = "test-sub-$(Get-Date -Format 'yyyyMMddHHmm')"
        $createSubUrl = "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroup/providers/Microsoft.ApiManagement/service/$ApimName/subscriptions/$testSubId"
        
        $body = @{
            properties = @{
                displayName = "Test Subscription"
                scope = "/apis"
                state = "active"
            }
        } | ConvertTo-Json -Depth 3
        
        try {
            $newSub = az rest `
                --method PUT `
                --url "$createSubUrl?api-version=2021-08-01" `
                --body $body `
                --headers "Content-Type=application/json" `
                --output json | ConvertFrom-Json
            
            if ($newSub) {
                $subscriptionKey = $newSub.properties.primaryKey
                Write-Host "✅ Created new test subscription!" -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Failed to create subscription. Manual setup required." -ForegroundColor Red
            Write-Host ""
            Write-Host "📋 Manual Steps:" -ForegroundColor Yellow
            Write-Host "1. Go to Azure Portal > API Management > $ApimName" -ForegroundColor White
            Write-Host "2. Navigate to 'Subscriptions' in the left menu" -ForegroundColor White
            Write-Host "3. Click '+ Add subscription'" -ForegroundColor White
            Write-Host "4. Create a subscription for 'All APIs' or specific API" -ForegroundColor White
            Write-Host "5. Copy the primary key and use it with your API calls" -ForegroundColor White
            exit 1
        }
    }
}

# Display the key (first 8 characters for security)
$maskedKey = $subscriptionKey.Substring(0, 8) + "..." + $subscriptionKey.Substring($subscriptionKey.Length - 4)
Write-Host "🔑 Subscription Key: $maskedKey" -ForegroundColor Cyan

# Test the API endpoints
Write-Host ""
Write-Host "🧪 Testing API Endpoints..." -ForegroundColor Yellow

$headers = @{
    'Ocp-Apim-Subscription-Key' = $subscriptionKey
    'Content-Type' = 'application/json'
}

$testEndpoints = @(
    @{ Name = "Health Check"; Url = "$gatewayUrl/api/health" },
    @{ Name = "Fox Status"; Url = "$gatewayUrl/api/fox" },
    @{ Name = "Fox Jump"; Url = "$gatewayUrl/api/fox/jump" },
    @{ Name = "Jump API"; Url = "$gatewayUrl/api/jump" }
)

foreach ($endpoint in $testEndpoints) {
    Write-Host ""
    Write-Host "Testing: $($endpoint.Name)" -ForegroundColor Gray
    Write-Host "URL: $($endpoint.Url)" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint.Url -Headers $headers -Method Get -ErrorAction Stop
        Write-Host "✅ Success!" -ForegroundColor Green
        Write-Host "   Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor White
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "❌ Failed (HTTP $statusCode)" -ForegroundColor Red
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $errorBody = $reader.ReadToEnd()
            Write-Host "   Error: $errorBody" -ForegroundColor Red
        }
    }
}

# Display usage instructions
Write-Host ""
Write-Host "🎯 API Usage Instructions:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔑 Your Subscription Key:" -ForegroundColor Yellow
Write-Host $subscriptionKey -ForegroundColor Green
Write-Host ""
Write-Host "📡 How to use with curl:" -ForegroundColor Yellow
Write-Host "curl -H `"Ocp-Apim-Subscription-Key: $subscriptionKey`" $gatewayUrl/api/health" -ForegroundColor White
Write-Host ""
Write-Host "📡 How to use with PowerShell:" -ForegroundColor Yellow
Write-Host "`$headers = @{ 'Ocp-Apim-Subscription-Key' = '$subscriptionKey' }" -ForegroundColor White
Write-Host "Invoke-RestMethod -Uri '$gatewayUrl/api/health' -Headers `$headers" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Test in Browser (with key in URL):" -ForegroundColor Yellow
Write-Host "$gatewayUrl/api/health?subscription-key=$subscriptionKey" -ForegroundColor White
Write-Host ""
Write-Host "📊 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test rate limiting with: .\test-apim-rate-limits.ps1" -ForegroundColor White
Write-Host "2. Visit the Developer Portal to manage subscriptions" -ForegroundColor White
Write-Host "3. Monitor API usage in Azure Portal" -ForegroundColor White
