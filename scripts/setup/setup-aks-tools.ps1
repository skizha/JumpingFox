# Install required tools for AKS deployment
# This script installs kubectl and Docker Desktop if not already installed

Write-Host "Setting up tools for AKS deployment..." -ForegroundColor Yellow

# Check if kubectl is installed
Write-Host "Checking kubectl..." -ForegroundColor Cyan
try {
    $kubectlVersion = kubectl version --client --output=yaml 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ kubectl is already installed" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  kubectl not found. Installing via Azure CLI..." -ForegroundColor Yellow
    az aks install-cli
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ kubectl installed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install kubectl" -ForegroundColor Red
    }
}

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Cyan
try {
    docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker is installed" -ForegroundColor Green
        
        # Check if Docker daemon is running
        docker ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker daemon is running" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Docker is installed but daemon is not running" -ForegroundColor Yellow
            Write-Host "   Please start Docker Desktop" -ForegroundColor White
        }
    }
} catch {
    Write-Host "⚠️  Docker not found" -ForegroundColor Yellow
    Write-Host "   Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor White
}

# Check Azure CLI extensions
Write-Host "Checking Azure CLI extensions..." -ForegroundColor Cyan
$extensions = az extension list --output json | ConvertFrom-Json
$aksExtension = $extensions | Where-Object { $_.name -eq "aks-preview" }

if (-not $aksExtension) {
    Write-Host "Installing AKS preview extension..." -ForegroundColor Yellow
    az extension add --name aks-preview
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AKS preview extension installed" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎯 Setup Summary:" -ForegroundColor Cyan
Write-Host "  • kubectl: Required for managing Kubernetes clusters" -ForegroundColor White
Write-Host "  • Docker: Used by ACR for building images" -ForegroundColor White  
Write-Host "  • Azure CLI: Already available for AKS management" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Ensure Docker Desktop is running" -ForegroundColor White
Write-Host "  2. Run: .\deploy-aks.ps1 to deploy to AKS" -ForegroundColor White
Write-Host ""
Write-Host "✅ Tool setup completed!" -ForegroundColor Green
