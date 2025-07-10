# AKS Deployment Script for JumpingFox API
# This script deploys the JumpingFox API to Azure Kubernetes Service (AKS)

param(
    [string]$ResourceGroup = "rg-jumpingfox-aks",
    [string]$Location = "East US",
    [string]$ClusterName = "jumpingfox-aks-cluster",
    [string]$RegistryName = "jumpingfoxacr$(Get-Date -Format 'yyyyMMdd')",
    [string]$AppName = "jumpingfox-api"
)

# Check if logged into Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show --query "user.name" --output tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not logged into Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in as: $account" -ForegroundColor Green

# Create resource group
Write-Host "Creating resource group: $ResourceGroup in $Location" -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create resource group" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Resource group created/verified" -ForegroundColor Green

# Create Azure Container Registry (ACR)
Write-Host "Creating Azure Container Registry: $RegistryName" -ForegroundColor Yellow
az acr create --resource-group $ResourceGroup --name $RegistryName --sku Basic --admin-enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create ACR" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure Container Registry created" -ForegroundColor Green

# Build and push Docker image to ACR
Write-Host "Building and pushing Docker image..." -ForegroundColor Yellow
az acr build --registry $RegistryName --image $AppName`:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build and push image" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker image built and pushed to ACR" -ForegroundColor Green

# Create AKS cluster (using system node pool with 1 node to minimize cost)
Write-Host "Creating AKS cluster: $ClusterName (this may take 5-10 minutes)..." -ForegroundColor Yellow
az aks create `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --node-count 1 `
    --node-vm-size Standard_B2s `
    --enable-managed-identity `
    --attach-acr $RegistryName `
    --generate-ssh-keys

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create AKS cluster" -ForegroundColor Red
    exit 1
}
Write-Host "✅ AKS cluster created successfully" -ForegroundColor Green

# Get AKS credentials
Write-Host "Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get AKS credentials" -ForegroundColor Red
    exit 1
}
Write-Host "✅ AKS credentials configured" -ForegroundColor Green

# Create Kubernetes deployment and service manifests
$deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $AppName
  labels:
    app: $AppName
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $AppName
  template:
    metadata:
      labels:
        app: $AppName
    spec:
      containers:
      - name: $AppName
        image: $RegistryName.azurecr.io/$AppName`:latest
        ports:
        - containerPort: 8080
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ASPNETCORE_URLS
          value: "http://+:8080"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: $AppName-service
spec:
  selector:
    app: $AppName
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
"@

# Write deployment manifest to file
$deploymentYaml | Out-File -FilePath "k8s-deployment.yaml" -Encoding UTF8

# Apply Kubernetes manifests
Write-Host "Deploying to AKS..." -ForegroundColor Yellow
kubectl apply -f k8s-deployment.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to deploy to AKS" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Application deployed to AKS" -ForegroundColor Green

# Wait for LoadBalancer to get external IP
Write-Host "Waiting for LoadBalancer to get external IP (this may take 2-5 minutes)..." -ForegroundColor Yellow
$attempts = 0
$maxAttempts = 30
$externalIP = ""

do {
    Start-Sleep 10
    $attempts++
    $serviceInfo = kubectl get service $AppName-service -o json | ConvertFrom-Json
    $externalIP = $serviceInfo.status.loadBalancer.ingress[0].ip
    Write-Host "Attempt $attempts/$maxAttempts - Checking for external IP..." -ForegroundColor Gray
} while ([string]::IsNullOrEmpty($externalIP) -and $attempts -lt $maxAttempts)

if ([string]::IsNullOrEmpty($externalIP)) {
    Write-Host "⚠️  LoadBalancer IP not ready yet. Check later with: kubectl get service $AppName-service" -ForegroundColor Yellow
    $externalIP = "PENDING"
} else {
    Write-Host "✅ LoadBalancer IP assigned: $externalIP" -ForegroundColor Green
}

# Display results
Write-Host ""
Write-Host "🎉 AKS Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Deployment Details:" -ForegroundColor Cyan
Write-Host "  📍 Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  🚢 AKS Cluster: $ClusterName" -ForegroundColor White
Write-Host "  📦 Container Registry: $RegistryName.azurecr.io" -ForegroundColor White
Write-Host "  🐳 Image: $RegistryName.azurecr.io/$AppName`:latest" -ForegroundColor White
Write-Host "  🌍 Region: $Location" -ForegroundColor White
Write-Host ""
if ($externalIP -ne "PENDING") {
    Write-Host "🔗 Application URLs:" -ForegroundColor Cyan
    Write-Host "  🏠 API Base URL: http://$externalIP" -ForegroundColor Green
    Write-Host "  📚 Swagger UI: http://$externalIP/" -ForegroundColor Green
    Write-Host "  ❤️  Health Check: http://$externalIP/health" -ForegroundColor Green
} else {
    Write-Host "⏳ Waiting for LoadBalancer IP. Check with:" -ForegroundColor Yellow
    Write-Host "   kubectl get service $AppName-service" -ForegroundColor White
}
Write-Host ""
Write-Host "📋 Useful Commands:" -ForegroundColor Yellow
Write-Host "  • View pods: kubectl get pods" -ForegroundColor White
Write-Host "  • View services: kubectl get services" -ForegroundColor White
Write-Host "  • View logs: kubectl logs -l app=$AppName" -ForegroundColor White
Write-Host "  • Scale app: kubectl scale deployment $AppName --replicas=3" -ForegroundColor White
Write-Host "  • Delete deployment: kubectl delete -f k8s-deployment.yaml" -ForegroundColor White
Write-Host ""
Write-Host "💰 Cost Optimization:" -ForegroundColor Yellow
Write-Host "  • Current setup uses 1 Standard_B2s node (~$30/month)" -ForegroundColor White
Write-Host "  • To stop cluster: az aks stop --name $ClusterName --resource-group $ResourceGroup" -ForegroundColor White
Write-Host "  • To start cluster: az aks start --name $ClusterName --resource-group $ResourceGroup" -ForegroundColor White
