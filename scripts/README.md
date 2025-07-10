# Scripts Directory

This directory contains all PowerShell scripts organized by category.

## 📁 Directory Structure

### 🚀 `/deployment`
Deployment scripts for various Azure services:
- `deploy.ps1` - Main deployment script using ARM templates
- `deploy-cli.ps1` - Command-line deployment script
- `deploy-aks.ps1` - Azure Kubernetes Service deployment

### ⚙️ `/setup`
Initial setup and configuration scripts:
- `setup-config.ps1` - Interactive configuration setup
- `setup-apim.ps1` - API Management setup
- `setup-aks-tools.ps1` - AKS tools installation

### 🧪 `/testing`
API and rate limiting testing scripts:
- `test-apim-rate-limits.ps1` - Comprehensive APIM rate limit testing
- `test-create-fox-rate-limit.ps1` - Create Fox endpoint rate limit testing
- `test-rate-limit.ps1` - Basic rate limit testing

### 🔧 `/utilities`
Utility and maintenance scripts:
- `security-check.ps1` - Security validation
- `get-apim-key.ps1` - Retrieve APIM subscription key
- `fix-openapi-spec.ps1` - OpenAPI specification fixes
- `cleanup-project.ps1` - Project cleanup
- `cleanup-aks.ps1` - AKS resource cleanup

## 📋 Usage

All scripts should be run from the root directory of the project:

```powershell
# Setup
.\scripts\setup\setup-config.ps1

# Deployment
.\scripts\deployment\deploy.ps1

# Testing
.\scripts\testing\test-apim-rate-limits.ps1

# Utilities
.\scripts\utilities\security-check.ps1
```

## 🔧 Configuration

Scripts use the shared configuration:
- `Config.ps1` (in root directory) - Configuration loader
- `config.json` (in root directory) - Configuration values
- `config.template.json` (in root directory) - Configuration template

Make sure to run `.\scripts\setup\setup-config.ps1` first to set up your configuration.
