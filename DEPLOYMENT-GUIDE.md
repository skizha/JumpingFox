# 🚀 Azure Deployment Guide for JumpingFox API

## Method 1: Automated Deployment Script (Recommended)

### Prerequisites:
1. **Install Azure CLI**: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows
2. **Azure Subscription** with Contributor permissions

### Quick Deployment:
```powershell
# 1. Login to Azure
az login

# 2. Set your subscription
az account set --subscription "your-subscription-id"

# 3. Run the deployment script
.\deploy.ps1
```

---

## Method 2: Manual Step-by-Step Deployment

### Step 1: Login and Setup
```powershell
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set your subscription (replace with your actual subscription ID)
az account set --subscription "12345678-1234-1234-1234-123456789012"

# Verify you're logged in
az account show
```

### Step 2: Create Resource Group
```powershell
# Create resource group
az group create --name "rg-jumpingfox" --location "East US"
```

### Step 3: Deploy Infrastructure
```powershell
# Deploy the ARM template
az deployment group create \
  --resource-group "rg-jumpingfox" \
  --template-file azure-deploy.json \
  --parameters webAppName="jumpingfox-api-unique" sku="B1"
```

### Step 4: Deploy Application Code

#### Option A: GitHub Actions (Recommended for Production)
1. **Push code to GitHub** (already done ✅)
2. **Set up GitHub Secrets**:
   - Go to your GitHub repository
   - Settings → Secrets and variables → Actions
   - Add secret: `AZUREAPPSERVICE_PUBLISHPROFILE`
   - Get publish profile from Azure portal:
     ```powershell
     az webapp deployment list-publishing-profiles \
       --name "jumpingfox-api-unique" \
       --resource-group "rg-jumpingfox" \
       --xml
     ```

#### Option B: Direct Deployment from Local
```powershell
# Build and package the application
dotnet publish -c Release -o ./publish

# Create deployment package
Compress-Archive -Path ./publish/* -DestinationPath ./jumpingfox.zip

# Deploy the zip file
az webapp deployment source config-zip \
  --resource-group "rg-jumpingfox" \
  --name "jumpingfox-api-unique" \
  --src "./jumpingfox.zip"
```

### Step 5: Verify Deployment
```powershell
# Get the app URL
$appUrl = az webapp show \
  --name "jumpingfox-api-unique" \
  --resource-group "rg-jumpingfox" \
  --query "defaultHostName" \
  --output tsv

# Test the health endpoint
curl "https://$appUrl/health"

# Open Swagger UI in browser
start "https://$appUrl/"
```

---

## Method 3: Azure Portal Deployment

### Step 1: Create App Service via Portal
1. **Go to Azure Portal**: https://portal.azure.com
2. **Create a resource** → **Web App**
3. **Configure**:
   - Resource Group: `rg-jumpingfox`
   - Name: `jumpingfox-api-unique`
   - Publish: `Code`
   - Runtime stack: `.NET 8 (LTS)`
   - Operating System: `Linux` or `Windows`
   - Region: `East US`
   - App Service Plan: `Basic B1`

### Step 2: Deploy Code
1. **Go to your Web App** in the portal
2. **Deployment Center** → **GitHub**
3. **Authorize and select**:
   - Organization: Your GitHub username
   - Repository: `jumpingfox-api`
   - Branch: `main`
4. **Save** - GitHub Actions will automatically deploy

---

## Method 4: Container Deployment

### Deploy to Azure Container Apps
```powershell
# Build and push Docker image
docker build -t jumpingfox-api .

# Tag for Azure Container Registry
docker tag jumpingfox-api youracr.azurecr.io/jumpingfox-api:latest

# Push to ACR
docker push youracr.azurecr.io/jumpingfox-api:latest

# Deploy to Container Apps
az containerapp create \
  --name jumpingfox-api \
  --resource-group rg-jumpingfox \
  --environment myenvironment \
  --image youracr.azurecr.io/jumpingfox-api:latest \
  --target-port 8080 \
  --ingress external
```

---

## Troubleshooting

### Common Issues:

1. **Azure CLI not found**:
   ```powershell
   # Install via winget
   winget install Microsoft.AzureCLI
   
   # Or download from: https://aka.ms/installazurecliwindows
   ```

2. **Permission denied**:
   - Ensure you have `Contributor` role on the subscription
   - Check with: `az role assignment list --assignee your-email@domain.com`

3. **App name already exists**:
   - App Service names must be globally unique
   - Try: `jumpingfox-api-$(Get-Random)`

4. **Deployment fails**:
   ```powershell
   # Check deployment logs
   az webapp log tail --name "your-app-name" --resource-group "rg-jumpingfox"
   
   # Check deployment status
   az webapp deployment list --name "your-app-name" --resource-group "rg-jumpingfox"
   ```

5. **503 Service Unavailable**:
   - Check Application Insights logs
   - Verify .NET 8 runtime is configured
   - Check startup logs in Azure portal

---

## Post-Deployment Steps

### 1. Test the API
```powershell
# Test health endpoint
$appUrl = "your-app-name.azurewebsites.net"
Invoke-RestMethod "https://$appUrl/health"

# Run rate limit tests
.\test-rate-limits.ps1 -BaseUrl "https://$appUrl"
```

### 2. Set up APIM
1. **Create API Management instance**
2. **Import OpenAPI** from: `https://your-app.azurewebsites.net/swagger/v1/swagger.json`
3. **Configure rate limiting policies** using `apim-policies-samples.xml`

### 3. Monitor and Scale
- Set up **Application Insights** for monitoring
- Configure **auto-scaling** based on CPU/memory
- Set up **alerts** for rate limit testing

---

## Cost Estimation

| Resource | Tier | Monthly Cost (USD) |
|----------|------|-------------------|
| App Service | B1 | ~$13-15 |
| App Service Plan | B1 | Included |
| **Total** | | **~$13-15/month** |

For production, consider:
- Standard tier for staging slots
- Premium tier for better performance
- APIM Developer tier for full features

---

## 🎯 Quick Start Commands

```powershell
# Complete deployment in 3 commands:
az login
az account set --subscription "your-subscription-id"
.\deploy.ps1
```

Your JumpingFox API will be ready for APIM rate limiting testing! 🦊
