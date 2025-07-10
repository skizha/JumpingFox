# Manual APIM Policy Update Guide

## 🚫 Automated Policy Update Failed

The automated script failed due to Azure resource validation errors. Here's how to manually apply the rate limit policies through the Azure Portal:

## 📋 Manual Steps

### Step 1: Access Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your APIM service: `jumpingfox-apim-20250709`
3. Go to **APIs** → **JumpingFox API**

### Step 2: Apply Overall API Policy (10,000 req/min)
1. Click on **All operations**
2. Go to **Policies** tab
3. Click on **</> Policy editor**
4. Replace the content with:

```xml
<policies>
    <!-- Throttle, authorize, validate, cache, or transform the requests -->
    <inbound>
        <base />
        <rate-limit-by-subscription calls="10000" renewal-period="60" />
        <set-header name="X-RateLimit-Type" exists-action="override">
            <value>Subscription-Based</value>
        </set-header>
        <set-header name="X-RateLimit-Limit" exists-action="override">
            <value>10000</value>
        </set-header>
    </inbound>
    <!-- Control if and how the requests are forwarded to services  -->
    <backend>
        <base />
    </backend>
    <!-- Customize the responses -->
    <outbound>
        <base />
    </outbound>
    <!-- Handle exceptions and customize error responses  -->
    <on-error>
        <base />
    </on-error>
</policies>
```

5. Click **Save**

### Step 3: Apply Create Fox Operation Policy (5 req/min per IP)
1. In the **JumpingFox API**, expand operations
2. Find and click on **POST /api/Fox** operation
3. Go to **Policies** tab
4. Click on **</> Policy editor**
5. Replace the content with:

```xml
<policies>
    <!-- Throttle, authorize, validate, cache, or transform the requests -->
    <inbound>
        <base />
        <rate-limit-by-key calls="5" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
        <set-header name="X-RateLimit-Type" exists-action="override">
            <value>IP-Based</value>
        </set-header>
        <set-header name="X-RateLimit-Limit" exists-action="override">
            <value>5</value>
        </set-header>
    </inbound>
    <!-- Control if and how the requests are forwarded to services  -->
    <backend>
        <base />
    </backend>
    <!-- Customize the responses -->
    <outbound>
        <base />
    </outbound>
    <!-- Handle exceptions and customize error responses  -->
    <on-error>
        <base />
    </on-error>
</policies>
```

6. Click **Save**

## 🧪 Test the Updated Policies

After applying the policies manually, test them:

```powershell
# Test Create Fox rate limiting (should allow 5 requests per minute per IP)
.\test-create-fox-rate-limit.ps1

# Test overall rate limiting (should allow 10,000 requests per minute)
.\test-rate-limit.ps1
```

## 📊 Expected Results

### Overall API (10,000 req/min):
- Much higher rate limit than before
- Should handle high traffic without rate limiting
- Based on subscription key

### Create Fox Operation (5 req/min per IP):
- Very restrictive limit for POST operations
- Based on client IP address
- Should rate limit after 5 requests per minute

## 🔧 Alternative: PowerShell Commands

If you prefer command line, try these PowerShell commands in the Azure Cloud Shell:

```powershell
# Set variables
$resourceGroup = "rg-jumpingfox-aks"
$serviceName = "jumpingfox-apim-20250709"
$apiId = "jumpingfox-api"

# Apply overall policy
$overallPolicy = @"
<policies>
    <inbound>
        <base />
        <rate-limit-by-subscription calls="10000" renewal-period="60" />
    </inbound>
    <backend><base /></backend>
    <outbound><base /></outbound>
    <on-error><base /></on-error>
</policies>
"@

Set-AzApiManagementPolicy -Context (Get-AzApiManagementContext -ResourceGroupName $resourceGroup -ServiceName $serviceName) -ApiId $apiId -Policy $overallPolicy

# Apply Create Fox operation policy
$createFoxPolicy = @"
<policies>
    <inbound>
        <base />
        <rate-limit-by-key calls="5" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
    </inbound>
    <backend><base /></backend>
    <outbound><base /></outbound>
    <on-error><base /></on-error>
</policies>
"@

Set-AzApiManagementPolicy -Context (Get-AzApiManagementContext -ResourceGroupName $resourceGroup -ServiceName $serviceName) -ApiId $apiId -OperationId "post-api-fox" -Policy $createFoxPolicy
```

## 📞 Verification

After applying the policies:
1. Wait 1-2 minutes for changes to propagate
2. Run the test scripts to verify the new rate limits
3. Check response headers for rate limit information

The manual approach through Azure Portal is the most reliable method for policy updates.
