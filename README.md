# JumpingFox API - APIM Rate Limiting Test Application

A .NET 8 Web API designed specifically for testing Azure API Management (APIM) rate limiting features. This application provides various endpoints with different characteristics to comprehensively test rate limiting scenarios.

## � Deployment Notice

**GitHub Actions deployments are disabled** for this public repository to prevent accidental deployments. See [GITHUB-ACTIONS-DISABLED.md](GITHUB-ACTIONS-DISABLED.md) for details on how to re-enable them for your own deployments.

## �🔐 Security & Configuration

**⚠️ IMPORTANT**: This repository contains scripts that work with Azure resources and API keys. Before using:

1. **Never commit sensitive data** - All configuration files are excluded from version control
2. **Use configuration files** - Copy `config.template.json` to `config.json` and update with your values
3. **Run setup script** - Use `.\setup-config.ps1` for interactive configuration setup

### Quick Start - Configuration Setup

```powershell
# 1. Clone the repository
git clone https://github.com/your-username/JumpingFox.git
cd JumpingFox

# 2. Set up configuration (interactive)
.\setup-config.ps1

# 3. Deploy to Azure
.\deploy.ps1

# 4. Test the API endpoints
.\test-apim-rate-limits.ps1
```

### Configuration Files

- `config.template.json` - Template with placeholder values (safe to commit)
- `config.json` - Your actual configuration with real values (DO NOT COMMIT)
- `.gitignore` - Protects sensitive files from being committed

## Features

### 🦊 Fox Management API
- **GET /api/fox** - Retrieve all foxes (good for collection endpoint rate limits)
- **GET /api/fox/{id}** - Get specific fox (individual resource access)
- **POST /api/fox** - Create new fox (POST operation rate limits)
- **PUT /api/fox/{id}** - Update fox (PUT operation rate limits)
- **DELETE /api/fox/{id}** - Delete fox (DELETE operation rate limits)
- **GET /api/fox/active** - Get only active foxes (filtered endpoints)
- **GET /api/fox/by-color/{color}** - Get foxes by color (query parameter endpoints)

### 🏃 Jump Records API
- **GET /api/jump** - Get all jump records (data-heavy endpoints)
- **GET /api/jump/fox/{foxId}** - Get jumps for specific fox (filtered data)
- **POST /api/jump** - Record new jump (POST with data processing)
- **GET /api/jump/top/{count}** - Get top jumps (computationally intensive)
- **GET /api/jump/stats** - Get jump statistics (analytics endpoints)

### 🧪 Rate Limit Testing API
- **GET /api/test/fast** - Fast response endpoint (~5ms)
- **GET /api/test/slow** - Slow response endpoint (~2000ms)
- **GET /api/test/memory-intensive** - Memory-intensive operations
- **POST /api/test/batch** - Batch operations (bulk processing)
- **GET /api/test/error/{errorType}** - Error simulation (400, 401, 403, 404, 429, 500)
- **POST /api/test/load** - Load testing with multiple internal operations
- **GET /api/test/metrics** - Get current request metrics
- **POST /api/test/metrics/reset** - Reset metrics for fresh testing

### 🔍 Monitoring & Health
- **GET /health** - Simple health check
- **Swagger UI** at root (`/`) for interactive API testing

## Rate Limiting Test Scenarios

This API is designed to test various APIM rate limiting scenarios:

1. **Frequency-based limits** - Use `/api/test/fast` for high-frequency testing
2. **Resource-intensive limits** - Use `/api/test/slow` and `/api/test/memory-intensive`
3. **Operation-specific limits** - Different HTTP methods on `/api/fox`
4. **Endpoint-specific limits** - Different rate limits per endpoint
5. **Error handling** - How rate limits interact with application errors
6. **Bulk operations** - Rate limiting batch processing with `/api/test/batch`
7. **Analytics endpoints** - Rate limiting expensive operations like `/api/jump/stats`

## Prerequisites

- .NET 8.0 SDK
- Azure CLI (for deployment)
- Docker (optional, for containerized deployment)

## Local Development

### Run locally:
```bash
cd JumpingFox
dotnet restore
dotnet run
```

The API will be available at:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`
- Swagger UI: `https://localhost:5001/`

### Build and Test:
```bash
dotnet build
dotnet test  # Add tests as needed
```

## Azure Deployment

### Option 1: Using Azure CLI (Recommended)

1. **Login to Azure:**
   ```powershell
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Run the deployment script:**
   ```powershell
   .\deploy.ps1
   ```

3. **Or deploy manually:**
   ```powershell
   # Create resource group
   az group create --name "rg-jumpingfox" --location "East US"
   
   # Deploy using ARM template
   az deployment group create \
     --resource-group "rg-jumpingfox" \
     --template-file azure-deploy.json \
     --parameters webAppName="jumpingfox-api-unique" sku="B1"
   ```

### Option 2: Using Docker + Container Registry

1. **Build and push Docker image:**
   ```bash
   docker build -t jumpingfox-api .
   docker tag jumpingfox-api your-registry.azurecr.io/jumpingfox-api:latest
   docker push your-registry.azurecr.io/jumpingfox-api:latest
   ```

2. **Deploy to Azure Container Apps or App Service**

### Option 3: GitHub Actions (CI/CD)

The repository is ready for GitHub Actions deployment. Create workflow files in `.github/workflows/` for automated deployments.

## APIM Configuration

### Rate Limiting Policy Examples:

You can configure APIM rate limiting policies in the Azure Portal. Here are some examples:

```xml
<!-- Per-subscription rate limiting -->
<rate-limit-by-subscription calls="100" renewal-period="60" />

<!-- Per-key rate limiting -->
<rate-limit-by-key calls="10" renewal-period="60" counter-key="@(context.Request.IpAddress)" />

<!-- Different limits for different endpoints -->
<choose>
    <when condition="@(context.Request.Url.Path.Contains("/api/test/fast"))">
        <rate-limit calls="1000" renewal-period="60" />
    </when>
    <when condition="@(context.Request.Url.Path.Contains("/api/test/slow"))">
        <rate-limit calls="10" renewal-period="60" />
    </when>
    <otherwise>
        <rate-limit calls="100" renewal-period="60" />
    </otherwise>
</choose>
```

## Testing Rate Limits

### Basic Testing:
```bash
# Test fast endpoint with high frequency
for i in {1..200}; do curl https://your-api.azurewebsites.net/api/test/fast; done

# Test slow endpoint
curl https://your-api.azurewebsites.net/api/test/slow

# Test batch operations
curl -X POST https://your-api.azurewebsites.net/api/test/batch \
  -H "Content-Type: application/json" \
  -d '{"clientId":"test-client","requestCount":25,"testType":"rate-limit-test"}'
```

### Advanced Testing with Different Clients:
```bash
# Test with different client identifiers
curl -H "X-Client-Id: client1" https://your-api.azurewebsites.net/api/fox
curl -H "X-Client-Id: client2" https://your-api.azurewebsites.net/api/fox
```

## Monitoring

- Check metrics: `GET /api/test/metrics`
- Reset metrics: `POST /api/test/metrics/reset`
- Health status: `GET /health`
- Application logs in Azure portal

## Architecture

```
JumpingFox/
├── Controllers/
│   ├── FoxController.cs      # Fox CRUD operations
│   ├── JumpController.cs     # Jump records and analytics
│   └── TestController.cs     # Rate limiting test endpoints
├── Models/
│   └── Models.cs            # Data models and DTOs
├── Services/
│   ├── DataService.cs       # In-memory data service
│   └── MetricsService.cs    # Request metrics tracking
├── Program.cs               # Application startup
├── Dockerfile              # Container configuration
└── azure-deploy.json       # ARM template for Azure deployment
```

## Contributing

Feel free to add more endpoints or scenarios for comprehensive APIM rate limiting testing!

## License

MIT License - Use freely for testing and learning purposes.
