# GitHub Actions Deployment - DISABLED

## 🚫 Deployment Workflows Disabled

The GitHub Actions deployment workflows have been disabled for the public release of this repository to prevent accidental deployments and protect sensitive Azure resources.

## 📋 Disabled Workflows

### 1. main.yml - Azure Web App Deployment
- **Purpose**: Builds and deploys the .NET API to Azure App Service
- **Triggers**: Previously ran on push to `main` and `develop` branches
- **Status**: ❌ **DISABLED** (manual trigger only)

### 2. docker.yml - Docker Build and Push
- **Purpose**: Builds Docker images and pushes to GitHub Container Registry
- **Triggers**: Previously ran on push to `main` branch and tags
- **Status**: ❌ **DISABLED** (manual trigger only)

## 🔧 How to Re-enable (For Private Deployments)

If you fork this repository and want to set up your own deployment:

### Step 1: Update Workflow Files
1. Edit `.github/workflows/main.yml`
2. Remove the `on: workflow_dispatch` line
3. Uncomment the original `on:` section with push/pull_request triggers

### Step 2: Configure Azure Secrets
Add these secrets to your GitHub repository:
- `AZUREAPPSERVICE_PUBLISHPROFILE` - Azure App Service publish profile
- `AZUREAPPSERVICE_PUBLISHPROFILE_STAGING` - Staging slot publish profile

### Step 3: Update Configuration
1. Update `AZURE_WEBAPP_NAME` in the workflow files
2. Update container registry settings in `docker.yml`
3. Configure your Azure resource group and subscription

## 🛡️ Security Considerations

### Why Workflows Are Disabled
1. **Prevent Accidental Deployments**: Avoid deploying to production environments
2. **Protect Azure Resources**: Prevent unauthorized access to Azure services
3. **Secure Repository**: Make the repository safe for public sharing
4. **Cost Control**: Prevent unexpected Azure usage charges

### Best Practices for Re-enabling
1. **Use Environments**: Configure GitHub Environments with approval requirements
2. **Limit Triggers**: Only deploy from specific branches (e.g., `main`)
3. **Secret Management**: Use Azure Key Vault or GitHub Secrets properly
4. **Resource Isolation**: Use separate Azure subscriptions for development/production

## 🚀 Manual Deployment Options

If you need to deploy this application, consider these alternatives:

### Option 1: Azure CLI Deployment
```bash
# Build and publish locally
dotnet publish -c Release -o ./publish

# Deploy to Azure App Service
az webapp deploy --resource-group your-rg --name your-app --src-path ./publish
```

### Option 2: Docker Deployment
```bash
# Build Docker image
docker build -t jumpingfox-api .

# Push to your registry
docker tag jumpingfox-api your-registry/jumpingfox-api
docker push your-registry/jumpingfox-api

# Deploy to Azure Container Apps/AKS
az containerapp update --name your-app --image your-registry/jumpingfox-api
```

### Option 3: Visual Studio Deployment
1. Right-click project in Visual Studio
2. Select "Publish"
3. Configure Azure App Service target
4. Deploy directly from IDE

## 📞 Support

For deployment questions or issues:
1. Check the original workflow files for configuration examples
2. Review Azure App Service documentation
3. Ensure your Azure subscription has the necessary permissions
4. Verify all required secrets are properly configured

## 🔄 Workflow Status

| Workflow | Status | Trigger | Last Action |
|----------|---------|---------|-------------|
| main.yml | ❌ Disabled | Manual only | Disabled for public release |
| docker.yml | ❌ Disabled | Manual only | Disabled for public release |

To check if workflows are working, you can manually trigger them from the GitHub Actions tab in your repository (if you have the necessary permissions and secrets configured).
