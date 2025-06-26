# 🚀 JumpingFox API - Quick Start Guide

## What is JumpingFox API?

JumpingFox is a .NET 8 Web API specifically designed for testing **Azure API Management (APIM) rate limiting** features. It provides multiple endpoints with different characteristics (fast, slow, memory-intensive, etc.) to comprehensively test various rate limiting scenarios.

## 🏃‍♂️ Quick Local Setup (2 minutes)

1. **Prerequisites**: .NET 8 SDK installed
2. **Clone and run**:
   ```powershell
   cd "c:\Sanjesh\Code\azure\JumpingFox"
   dotnet run
   ```
3. **Open browser**: `https://localhost:5001` (Swagger UI)

## ☁️ Deploy to Azure (5 minutes)

### Option 1: Automated Deployment
```powershell
# Update the script variables first!
.\deploy.ps1
```

### Option 2: Manual Azure CLI
```powershell
# Login to Azure
az login
az account set --subscription "your-subscription-id"

# Create resource group and deploy
az group create --name "rg-jumpingfox" --location "East US"
az deployment group create --resource-group "rg-jumpingfox" --template-file azure-deploy.json --parameters webAppName="jumpingfox-api-unique"

# Deploy code (create a zip of your source first)
az webapp deployment source config-zip --resource-group "rg-jumpingfox" --name "jumpingfox-api-unique" --src "jumpingfox.zip"
```

## 🧪 Test Rate Limiting (3 minutes)

### Basic Test (Manual)
```powershell
# Replace with your deployed URL
$apiUrl = "https://jumpingfox-api-unique.azurewebsites.net"

# Test fast endpoint multiple times
for ($i=1; $i -le 50; $i++) { 
    Invoke-RestMethod "$apiUrl/api/test/fast" 
}
```

### Automated Test Suite
```powershell
# Run comprehensive rate limit tests
.\test-rate-limits.ps1 -BaseUrl "https://your-api.azurewebsites.net" -SubscriptionKey "your-apim-key"
```

## 🎯 Key Testing Endpoints

| Endpoint | Purpose | Ideal For Testing |
|----------|---------|------------------|
| `/api/test/fast` | Quick responses (~5ms) | High-frequency rate limits |
| `/api/test/slow` | Slow responses (~2s) | Time-based limiting |
| `/api/test/memory-intensive` | Memory usage | Resource-based limits |
| `/api/test/batch` | Bulk operations | Batch processing limits |
| `/api/fox` (CRUD) | Standard operations | Per-method rate limits |
| `/api/jump/stats` | Analytics | Expensive operation limits |

## 🔧 APIM Configuration

1. **Import API**: Add your deployed JumpingFox API to APIM
2. **Apply Policies**: Use the sample policies from `apim-policies-samples.xml`
3. **Test Different Scenarios**:
   - Per-subscription limits
   - Per-IP limits  
   - Endpoint-specific limits
   - Tiered rate limiting

### Sample APIM Policy (Basic)
```xml
<policies>
    <inbound>
        <rate-limit-by-subscription calls="100" renewal-period="60" />
    </inbound>
</policies>
```

## 📊 Monitor Results

- **Real-time metrics**: `GET /api/test/metrics`
- **Reset counters**: `POST /api/test/metrics/reset`
- **Health check**: `GET /health`
- **Swagger UI**: Available at root URL `/`

## 🔗 What's Next?

1. **Set up APIM**: Create an APIM instance and import your API
2. **Configure rate limits**: Apply different policies from the samples
3. **Run tests**: Use the provided PowerShell script
4. **Monitor and adjust**: Fine-tune your rate limiting policies
5. **Scale testing**: Use multiple clients and subscription keys

## 📁 Project Structure

```
JumpingFox/
├── Controllers/           # API endpoints
├── Models/               # Data models
├── Services/            # Business logic
├── apim-policies-samples.xml  # Sample APIM policies
├── test-rate-limits.ps1      # Automated testing script
├── deploy.ps1               # Azure deployment script
└── README.md               # Full documentation
```

## 🆘 Troubleshooting

**Build fails?** 
- Ensure .NET 8 SDK is installed: `dotnet --version`

**Deployment fails?**
- Check Azure CLI is logged in: `az account show`
- Ensure unique web app name in deploy script

**No rate limiting detected?**
- Check APIM policies are applied correctly
- Verify subscription keys are being used
- Monitor APIM analytics dashboard

**Questions?** Check the full `README.md` for detailed documentation!

---
🎉 **You're ready to test APIM rate limiting with JumpingFox!**
