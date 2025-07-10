# Connecting AKS to Azure API Management (APIM) - Step-by-Step Guide

## 🎯 Overview
This guide walks you through connecting your AKS-deployed JumpingFox API to Azure API Management for enterprise-grade API management, rate limiting, and monitoring.

## 📋 Prerequisites
- ✅ AKS cluster running (deployed successfully)
- ✅ JumpingFox API accessible at: http://134.33.206.69
- ✅ Azure CLI logged in
- ✅ Resource group: rg-jumpingfox-aks

## 🚀 Quick Setup (Automated)
Run the automated setup script:
```powershell
.\setup-apim.ps1
```

## 📖 Manual Setup Steps

### Step 1: Create APIM Instance
```bash
# Create APIM instance (Developer tier - $50/month)
az apim create \
    --name "jumpingfox-apim-$(date +%Y%m%d)" \
    --resource-group "rg-jumpingfox-aks" \
    --location "East US" \
    --publisher-email "your-email@domain.com" \
    --publisher-name "Your Name" \
    --sku-name Developer \
    --no-wait
```

⏰ **Note**: APIM creation takes 30-45 minutes!

### Step 2: Check APIM Status
```bash
# Check if APIM is ready
az apim show \
    --name "jumpingfox-apim-YYYYMMDD" \
    --resource-group "rg-jumpingfox-aks" \
    --query "provisioningState"
```

### Step 3: Create API in APIM
```bash
# Create the API
az apim api create \
    --resource-group "rg-jumpingfox-aks" \
    --service-name "jumpingfox-apim-YYYYMMDD" \
    --api-id "jumpingfox-api" \
    --path "/api" \
    --display-name "JumpingFox API" \
    --description "JumpingFox API for rate limiting and testing" \
    --service-url "http://134.33.206.69" \
    --protocols "http,https"
```

### Step 4: Import OpenAPI Definition (Optional)
```bash
# Download OpenAPI spec from your AKS service
curl http://134.33.206.69/swagger/v1/swagger.json -o swagger.json

# Import the OpenAPI definition
az apim api import \
    --resource-group "rg-jumpingfox-aks" \
    --service-name "jumpingfox-apim-YYYYMMDD" \
    --api-id "jumpingfox-api" \
    --specification-format "OpenApi" \
    --specification-path "swagger.json" \
    --path "/api"
```

### Step 5: Apply Rate Limiting Policies

#### Option A: Use Azure Portal
1. Go to Azure Portal → API Management
2. Select your APIM instance
3. Go to APIs → JumpingFox API
4. Click "All operations" or specific operation
5. In "Inbound processing" → click "</>" (code view)
6. Paste policy from `apim-policies-samples.xml`

#### Option B: Use CLI
```bash
# Create policy file
cat > api-policy.xml << 'EOF'
<policies>
    <inbound>
        <base />
        <rate-limit-by-subscription calls="100" renewal-period="60" />
        <set-header name="X-Correlation-Id" exists-action="override">
            <value>@(Guid.NewGuid().ToString())</value>
        </set-header>
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
EOF

# Apply the policy
az apim api policy create \
    --resource-group "rg-jumpingfox-aks" \
    --service-name "jumpingfox-apim-YYYYMMDD" \
    --api-id "jumpingfox-api" \
    --policy-file "api-policy.xml"
```

## 🔗 Architecture Overview

```
Internet → APIM Gateway → AKS LoadBalancer → Kubernetes Pods
   ↓           ↓              ↓                    ↓
Clients → Rate Limiting → Load Balancing → JumpingFox API
```

## 🎯 Testing Your Setup

### 1. Get APIM URLs
```bash
az apim show \
    --name "jumpingfox-apim-YYYYMMDD" \
    --resource-group "rg-jumpingfox-aks" \
    --query "{gatewayUrl:gatewayUrl,portalUrl:portalUrl}"
```

### 2. Create Subscription Key
1. Visit Developer Portal: `https://your-apim.portal.azure-api.net/`
2. Sign up / Sign in
3. Go to Products → Starter
4. Subscribe to get a subscription key

### 3. Test the API
```bash
# Test through APIM (with rate limiting)
curl -H "Ocp-Apim-Subscription-Key: YOUR_KEY" \
     https://your-apim.azure-api.net/api/fox/jump

# Test directly to AKS (no rate limiting)
curl http://134.33.206.69/api/fox/jump
```

### 4. Test Rate Limiting
```powershell
# Use our testing script
.\test-apim-rate-limits.ps1 \
    -ApimGatewayUrl "https://your-apim.azure-api.net" \
    -SubscriptionKey "your-subscription-key"
```

## 📊 Available Rate Limiting Policies

You have several pre-configured policies in `apim-policies-samples.xml`:

1. **Basic Subscription-based**: 100 calls/minute per subscription
2. **IP-based**: 50 calls/minute per IP address  
3. **Endpoint-specific**: Different limits per endpoint
4. **Client ID-based**: Custom client identification
5. **Tiered**: Different limits for Premium/Standard/Basic subscriptions
6. **Quota-based**: Monthly quotas + per-minute limits
7. **Advanced**: Custom error responses

## 🌐 Key URLs After Setup

| Service | URL | Purpose |
|---------|-----|---------|
| **Direct AKS** | http://134.33.206.69 | Direct access (no rate limiting) |
| **APIM Gateway** | https://your-apim.azure-api.net | Rate-limited API access |
| **Developer Portal** | https://your-apim.portal.azure-api.net | Get subscription keys, documentation |
| **Azure Portal** | portal.azure.com | APIM management, analytics |

## 💰 Cost Breakdown

| Component | Tier | Monthly Cost |
|-----------|------|--------------|
| **AKS Cluster** | 1 Standard_B2s node | ~$30 |
| **APIM** | Developer tier | ~$50 |
| **ACR** | Basic | ~$5 |
| **Total** | | **~$85/month** |

## 🔧 Advanced Configuration

### Custom Backends
You can configure multiple backends:
```bash
# Add staging backend
az apim backend create \
    --resource-group "rg-jumpingfox-aks" \
    --service-name "jumpingfox-apim-YYYYMMDD" \
    --backend-id "jumpingfox-staging" \
    --url "http://staging-ip" \
    --protocol "http"
```

### Environment-specific Policies
- **Development**: High rate limits, detailed logging
- **Staging**: Moderate limits, monitoring
- **Production**: Strict limits, caching, security

### Monitoring & Analytics
- View requests/responses in Azure Portal
- Set up alerts for rate limit breaches
- Monitor backend health
- Track API usage patterns

## 🎉 Next Steps

1. **Apply Advanced Policies**: Use examples from `apim-policies-samples.xml`
2. **Set Up Monitoring**: Configure alerts and dashboards
3. **API Documentation**: Customize Developer Portal
4. **Security**: Add OAuth, JWT validation
5. **Caching**: Enable response caching for better performance
6. **Multi-environment**: Create separate APIs for dev/staging/prod

## 🆘 Troubleshooting

### Common Issues:
1. **APIM not accessible**: Wait for provisioning to complete (30-45 min)
2. **Backend not reachable**: Check AKS LoadBalancer IP
3. **Rate limiting not working**: Verify policy is applied correctly
4. **Subscription key missing**: Create subscription in Developer Portal

### Useful Commands:
```bash
# Check APIM status
az apim show --name YOUR_APIM --resource-group rg-jumpingfox-aks

# Check AKS service
kubectl get services

# View APIM logs
az monitor activity-log list --resource-group rg-jumpingfox-aks
```

## 📝 **OpenAPI 3.0.1 Compatibility**

### ✅ **Full Compatibility Confirmed**
Your JumpingFox API generates OpenAPI 3.0.1 specification that is:
- **APIM Compatible**: Directly importable into Azure API Management
- **Industry Standard**: Latest widely-adopted OpenAPI version
- **Feature Complete**: Includes schemas, parameters, responses
- **Auto-Generated**: Updated automatically when you modify controllers

### **Generated Specification Details:**
```json
{
  "openapi": "3.0.1",
  "info": {
    "title": "JumpingFox API",
    "description": "API for testing APIM rate limiting scenarios",
    "version": "v1"
  },
  "paths": { /* 18+ endpoints documented */ },
  "components": { /* Complete schema definitions */ }
}
```

### **Available Endpoints in OpenAPI:**
- **Fox Management**: `/api/Fox/*` - CRUD operations for foxes
- **Jump Records**: `/api/Jump/*` - Jump tracking and statistics  
- **Rate Limit Testing**: `/api/Test/*` - Endpoints for testing policies
- **Health Check**: `/health` - Service health monitoring

### **APIM Import Benefits:**
1. **Automatic Documentation**: Generated in Developer Portal
2. **Schema Validation**: Request/response validation
3. **Interactive Testing**: Built-in "Try It Out" functionality
4. **Client SDKs**: Auto-generated code samples
5. **Policy Targeting**: Apply policies to specific endpoints

### **OpenAPI Features Used:**
- ✅ Path parameters (`{id}`, `{foxId}`, `{color}`)
- ✅ Request/Response schemas
- ✅ HTTP method definitions
- ✅ Content type specifications
- ✅ Component references (`$ref`)
- ✅ Structured error responses
