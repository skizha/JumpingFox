# Azure API Management (APIM) Integration with AKS
# This script creates APIM and connects it to your AKS-deployed JumpingFox API

param(
    [string]$ResourceGroup = "rg-jumpingfox-aks",
    [string]$Location = "East US", 
    [string]$ApimName = "jumpingfox-apim-$(Get-Date -Format 'yyyyMMdd')",
    [string]$PublisherEmail = "sanjesh.vasu@campuscloud.io",
    [string]$PublisherName = "JumpingFox Team",
    [string]$ApiName = "jumpingfox-api",
    [string]$BackendUrl = "http://134.33.206.69"  # Your AKS LoadBalancer IP
)

Write-Host "🚀 Setting up Azure API Management for JumpingFox AKS Deployment" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Check if logged into Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show --query "user.name" --output tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged into Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in as: $account" -ForegroundColor Green

# Step 1: Create APIM instance (Developer tier for cost optimization)
Write-Host ""
Write-Host "📋 Step 1: Creating APIM Instance..." -ForegroundColor Yellow
Write-Host "⏰ This will take 30-45 minutes for a new APIM instance" -ForegroundColor Gray
az apim create `
    --name $ApimName `
    --resource-group $ResourceGroup `
    --location $Location `
    --publisher-email $PublisherEmail `
    --publisher-name $PublisherName `
    --sku-name Developer `
    --no-wait

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ APIM creation initiated (running in background)" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create APIM instance" -ForegroundColor Red
    exit 1
}

# Step 2: Wait for APIM to be ready (check every 2 minutes)
Write-Host ""
Write-Host "📋 Step 2: Waiting for APIM to be ready..." -ForegroundColor Yellow
$maxWaitMinutes = 45
$checkIntervalMinutes = 2
$attempts = 0
$maxAttempts = [math]::Ceiling($maxWaitMinutes / $checkIntervalMinutes)

do {
    $attempts++
    Write-Host "⏰ Attempt $attempts/$maxAttempts - Checking APIM status..." -ForegroundColor Gray
    
    $apimStatus = az apim show --name $ApimName --resource-group $ResourceGroup --query "provisioningState" --output tsv 2>$null
    
    if ($apimStatus -eq "Succeeded") {
        Write-Host "✅ APIM instance is ready!" -ForegroundColor Green
        break
    } elseif ($apimStatus -eq "Failed") {
        Write-Host "❌ APIM creation failed" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "🔄 APIM status: $apimStatus - waiting $checkIntervalMinutes minutes..." -ForegroundColor Gray
        Start-Sleep (60 * $checkIntervalMinutes)
    }
} while ($attempts -lt $maxAttempts)

if ($attempts -eq $maxAttempts) {
    Write-Host "⏰ APIM is still being created. You can continue manually once it's ready." -ForegroundColor Yellow
    Write-Host "   Check status: az apim show --name $ApimName --resource-group $ResourceGroup --query provisioningState" -ForegroundColor Gray
    Write-Host "   Then run the API import manually using the steps below." -ForegroundColor Gray
} else {
    # Step 3: Create API in APIM
    Write-Host ""
    Write-Host "📋 Step 3: Creating API in APIM..." -ForegroundColor Yellow
    
    # Download the OpenAPI 3.0.1 specification from your AKS service
    Write-Host "Getting OpenAPI 3.0.1 definition from AKS service..." -ForegroundColor Gray
    
    try {
        $swaggerUrl = "$BackendUrl/swagger/v1/swagger.json"
        $response = Invoke-WebRequest -Uri $swaggerUrl -ErrorAction Stop
        $openApiSpec = $response.Content | ConvertFrom-Json
        
        # Verify OpenAPI version
        if ($openApiSpec.openapi -eq "3.0.1") {
            Write-Host "✅ Downloaded OpenAPI 3.0.1 specification with $($openApiSpec.paths.Count) endpoints" -ForegroundColor Green
            
            # Clean the OpenAPI spec for APIM compatibility
            Write-Host "🧹 Cleaning OpenAPI spec for APIM compatibility..." -ForegroundColor Gray
            
            # Fix invalid schema names that contain special characters
            if ($openApiSpec.components -and $openApiSpec.components.schemas) {
                $schemasToFix = @()
                $openApiSpec.components.schemas.PSObject.Properties | ForEach-Object {
                    if ($_.Name -match '[<>]') {
                        $schemasToFix += @{
                            OriginalName = $_.Name
                            CleanName = $_.Name -replace '[<>]', '' -replace '[^a-zA-Z0-9\.\-_]', '_'
                        }
                    }
                }
                
                # Apply schema name fixes
                foreach ($schemaFix in $schemasToFix) {
                    Write-Host "  Fixing schema: '$($schemaFix.OriginalName)' -> '$($schemaFix.CleanName)'" -ForegroundColor Gray
                    
                    # Rename the schema
                    $schemaDefinition = $openApiSpec.components.schemas.($schemaFix.OriginalName)
                    $openApiSpec.components.schemas | Add-Member -MemberType NoteProperty -Name $schemaFix.CleanName -Value $schemaDefinition -Force
                    $openApiSpec.components.schemas.PSObject.Properties.Remove($schemaFix.OriginalName)
                    
                    # Update all references to this schema in the spec
                    $specJson = $openApiSpec | ConvertTo-Json -Depth 20
                    $specJson = $specJson -replace [regex]::Escape("#/components/schemas/$($schemaFix.OriginalName)"), "#/components/schemas/$($schemaFix.CleanName)"
                    $openApiSpec = $specJson | ConvertFrom-Json
                }
                
                if ($schemasToFix.Count -gt 0) {
                    Write-Host "✅ Fixed $($schemasToFix.Count) invalid schema name(s)" -ForegroundColor Green
                }
            }
            
            # Save the cleaned spec
            $openApiSpec | ConvertTo-Json -Depth 20 | Out-File "swagger.json" -Encoding UTF8
            Write-Host "✅ Cleaned OpenAPI spec saved" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Unexpected OpenAPI version: $($openApiSpec.openapi)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not download OpenAPI definition from $swaggerUrl" -ForegroundColor Yellow
        Write-Host "   Will create API manually..." -ForegroundColor Gray
    }
    
    # Create the API
    az apim api create `
        --resource-group $ResourceGroup `
        --service-name $ApimName `
        --api-id $ApiName `
        --path "/api" `
        --display-name "JumpingFox API" `
        --description "JumpingFox API for rate limiting and testing" `
        --service-url $BackendUrl `
        --protocols "http,https"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ API created in APIM" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create API in APIM" -ForegroundColor Red
    }
    
    # Step 4: Import OpenAPI definition (if available)
    if (Test-Path "swagger.json") {
        Write-Host "Cleaning and importing OpenAPI definition..." -ForegroundColor Gray
        
        # Read and clean the OpenAPI specification
        try {
            $openApiContent = Get-Content "swagger.json" -Raw | ConvertFrom-Json
            
            # Fix invalid schema names that contain special characters
            if ($openApiContent.components -and $openApiContent.components.schemas) {
                $schemasToFix = @()
                $openApiContent.components.schemas.PSObject.Properties | ForEach-Object {
                    if ($_.Name -match '[<>]|f__AnonymousType') {
                        $schemasToFix += @{
                            OriginalName = $_.Name
                            CleanName = $_.Name -replace '[<>]', '' -replace 'f__AnonymousType\d*', 'AnonymousType' -replace '[^a-zA-Z0-9\.\-_]', '_'
                        }
                    }
                }
                
                # Apply schema name fixes
                foreach ($schemaFix in $schemasToFix) {
                    Write-Host "  Fixing schema: '$($schemaFix.OriginalName)' -> '$($schemaFix.CleanName)'" -ForegroundColor Gray
                    
                    # Rename the schema
                    $schemaDefinition = $openApiContent.components.schemas.($schemaFix.OriginalName)
                    $openApiContent.components.schemas | Add-Member -MemberType NoteProperty -Name $schemaFix.CleanName -Value $schemaDefinition -Force
                    $openApiContent.components.schemas.PSObject.Properties.Remove($schemaFix.OriginalName)
                    
                    # Update all references to this schema in the spec
                    $specJson = $openApiContent | ConvertTo-Json -Depth 20
                    $specJson = $specJson -replace [regex]::Escape("#/components/schemas/$($schemaFix.OriginalName)"), "#/components/schemas/$($schemaFix.CleanName)"
                    $openApiContent = $specJson | ConvertFrom-Json
                }
                
                if ($schemasToFix.Count -gt 0) {
                    Write-Host "  ✅ Fixed $($schemasToFix.Count) invalid schema name(s)" -ForegroundColor Green
                }
            }
            
            # Save the cleaned specification
            $cleanedJson = $openApiContent | ConvertTo-Json -Depth 20
            $cleanedJson | Out-File "swagger-clean.json" -Encoding UTF8
            
            # Import the cleaned specification
            az apim api import `
                --resource-group $ResourceGroup `
                --service-name $ApimName `
                --api-id $ApiName `
                --specification-format "OpenApi" `
                --specification-path "swagger-clean.json" `
                --path "/api"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Cleaned OpenAPI definition imported successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠️  OpenAPI import failed, but API was created manually" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "⚠️  Error cleaning OpenAPI spec: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "   Proceeding with manual API creation..." -ForegroundColor Gray
        }
    }
    
    # Step 5: Apply rate limiting policy
    Write-Host ""
    Write-Host "📋 Step 4: Applying rate limiting policies..." -ForegroundColor Yellow
    
    # Create a policy file with basic rate limiting
    $policyXml = @"
<policies>
    <inbound>
        <base />
        <!-- Basic rate limiting: 100 calls per minute per subscription -->
        <rate-limit-by-subscription calls="100" renewal-period="60" />
        
        <!-- Add correlation ID for tracking -->
        <set-header name="X-Correlation-Id" exists-action="override">
            <value>@(Guid.NewGuid().ToString())</value>
        </set-header>
        
        <!-- CORS for web clients -->
        <cors allow-credentials="false">
            <allowed-origins>
                <origin>*</origin>
            </allowed-origins>
            <allowed-methods>
                <method>GET</method>
                <method>POST</method>
                <method>PUT</method>
                <method>DELETE</method>
            </allowed-methods>
            <allowed-headers>
                <header>*</header>
            </allowed-headers>
        </cors>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <!-- Add rate limit headers for debugging -->
        <set-header name="X-RateLimit-Limit" exists-action="override">
            <value>100</value>
        </set-header>
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
"@
    
    $policyXml | Out-File -FilePath "api-policy.xml" -Encoding UTF8
    
    # Apply the policy
    az apim api policy create `
        --resource-group $ResourceGroup `
        --service-name $ApimName `
        --api-id $ApiName `
        --policy-file "api-policy.xml"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Rate limiting policy applied" -ForegroundColor Green
    }
}

# Step 6: Get APIM details
Write-Host ""
Write-Host "📋 Step 5: Getting APIM Details..." -ForegroundColor Yellow

$apimDetails = az apim show --name $ApimName --resource-group $ResourceGroup --output json | ConvertFrom-Json

if ($apimDetails) {
    $gatewayUrl = "https://$($apimDetails.gatewayUrl.TrimStart('https://'))"
    $managementUrl = "https://$($apimDetails.managementApiUrl.TrimStart('https://'))"
    $portalUrl = "https://$($apimDetails.portalUrl.TrimStart('https://'))"
    
    Write-Host ""
    Write-Host "🎉 APIM Setup Completed!" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 APIM Details:" -ForegroundColor Cyan
    Write-Host "  📍 Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "  🏢 APIM Name: $ApimName" -ForegroundColor White
    Write-Host "  🌍 Region: $Location" -ForegroundColor White
    Write-Host ""
    Write-Host "🔗 Important URLs:" -ForegroundColor Cyan
    Write-Host "  🚪 Gateway URL: $gatewayUrl" -ForegroundColor Green
    Write-Host "  🎯 API Endpoint: $gatewayUrl/api" -ForegroundColor Green
    Write-Host "  📊 Developer Portal: $portalUrl" -ForegroundColor Green
    Write-Host "  ⚙️  Management URL: $managementUrl" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Backend Connection:" -ForegroundColor Cyan
    Write-Host "  🏠 AKS Service: $BackendUrl" -ForegroundColor White
    Write-Host "  📡 APIM Gateway: Routes traffic to AKS" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Create subscription keys in APIM Developer Portal" -ForegroundColor White
    Write-Host "  2. Test the API through APIM: $gatewayUrl/api/fox/jump" -ForegroundColor White
    Write-Host "  3. Apply advanced policies from apim-policies-samples.xml" -ForegroundColor White
    Write-Host "  4. Monitor rate limits and usage in Azure Portal" -ForegroundColor White
    Write-Host "  5. Use .\test-apim-rate-limits.ps1 to test rate limiting" -ForegroundColor White
    Write-Host ""
    Write-Host "💰 Cost Information:" -ForegroundColor Yellow
    Write-Host "  • APIM Developer tier: ~$50/month" -ForegroundColor White
    Write-Host "  • AKS cluster: ~$30/month" -ForegroundColor White
    Write-Host "  • Total estimated cost: ~$80/month" -ForegroundColor White
}

# Clean up temporary files
if (Test-Path "swagger.json") { Remove-Item "swagger.json" }
if (Test-Path "swagger-clean.json") { Remove-Item "swagger-clean.json" }
if (Test-Path "api-policy.xml") { Remove-Item "api-policy.xml" }
