# Cleanup script for JumpingFox AKS deployment
# This script provides options to clean up different levels of the deployment

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("app", "cluster", "all", "help")]
    [string]$Scope = "help",
    
    [string]$ResourceGroup = "rg-jumpingfox-aks",
    [string]$ClusterName = "jumpingfox-aks-cluster",
    [string]$RegistryName = "jumpingfoxacr20250703",
    [string]$AppName = "jumpingfox-api"
)

function Show-Help {
    Write-Host ""
    Write-Host "🧹 JumpingFox AKS Cleanup Script" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\cleanup-aks.ps1 -Scope <scope>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Cleanup Scopes:" -ForegroundColor White
    Write-Host "  app     - Remove only the application from Kubernetes (keeps cluster)" -ForegroundColor Green
    Write-Host "  cluster - Remove the entire AKS cluster (keeps resource group & ACR)" -ForegroundColor Yellow
    Write-Host "  all     - Remove everything (resource group, cluster, ACR)" -ForegroundColor Red
    Write-Host "  help    - Show this help message" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\cleanup-aks.ps1 -Scope app     # Remove just the app deployment" -ForegroundColor Gray
    Write-Host "  .\cleanup-aks.ps1 -Scope cluster # Remove AKS cluster only" -ForegroundColor Gray
    Write-Host "  .\cleanup-aks.ps1 -Scope all     # Remove everything" -ForegroundColor Gray
    Write-Host ""
}

function Remove-Application {
    Write-Host "🗑️  Removing application deployment..." -ForegroundColor Yellow
    
    # Check if kubectl is configured
    try {
        kubectl get nodes 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  kubectl not configured for AKS cluster. Getting credentials..." -ForegroundColor Yellow
            az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing
        }
    } catch {
        Write-Host "❌ Unable to connect to AKS cluster" -ForegroundColor Red
        return
    }
    
    # Delete Kubernetes resources
    Write-Host "Deleting Kubernetes deployment..." -ForegroundColor Gray
    kubectl delete deployment $AppName 2>$null
    
    Write-Host "Deleting Kubernetes service..." -ForegroundColor Gray
    kubectl delete service "$AppName-service" 2>$null
    
    Write-Host "Deleting Kubernetes ingress (if exists)..." -ForegroundColor Gray
    kubectl delete ingress "$AppName-ingress" 2>$null
    
    # Clean up generated files
    if (Test-Path "k8s-deployment.yaml") {
        Remove-Item "k8s-deployment.yaml" -Force
        Write-Host "Removed k8s-deployment.yaml" -ForegroundColor Gray
    }
    
    Write-Host "✅ Application removed from cluster" -ForegroundColor Green
    Write-Host "💡 Cluster is still running. Use -Scope cluster to remove it." -ForegroundColor Cyan
}

function Remove-Cluster {
    Write-Host "🗑️  Removing AKS cluster..." -ForegroundColor Yellow
    
    # Remove the cluster
    Write-Host "Deleting AKS cluster: $ClusterName (this may take 5-10 minutes)..." -ForegroundColor Gray
    az aks delete --name $ClusterName --resource-group $ResourceGroup --yes --no-wait
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AKS cluster deletion initiated" -ForegroundColor Green
        Write-Host "💡 ACR and Resource Group are preserved. Use -Scope all to remove everything." -ForegroundColor Cyan
    } else {
        Write-Host "❌ Failed to delete AKS cluster" -ForegroundColor Red
    }
}

function Remove-Everything {
    Write-Host "🗑️  Removing ALL resources..." -ForegroundColor Red
    Write-Host "⚠️  This will delete the entire resource group and all contained resources!" -ForegroundColor Yellow
    
    $confirmation = Read-Host "Are you sure you want to delete everything? Type 'YES' to confirm"
    
    if ($confirmation -eq "YES") {
        Write-Host "Deleting resource group: $ResourceGroup..." -ForegroundColor Gray
        az group delete --name $ResourceGroup --yes --no-wait
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Resource group deletion initiated" -ForegroundColor Green
            Write-Host "🕐 This process will take several minutes to complete." -ForegroundColor Cyan
            
            # Clean up local kubectl context
            Write-Host "Cleaning up kubectl context..." -ForegroundColor Gray
            kubectl config delete-context $ClusterName 2>$null
            kubectl config delete-cluster $ClusterName 2>$null
            
            # Clean up generated files
            $filesToClean = @("k8s-deployment.yaml", "k8s-manifests.yaml")
            foreach ($file in $filesToClean) {
                if (Test-Path $file) {
                    Remove-Item $file -Force
                    Write-Host "Removed $file" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "❌ Failed to delete resource group" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Deletion cancelled" -ForegroundColor Yellow
    }
}

function Show-Status {
    Write-Host ""
    Write-Host "📊 Current Status:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    # Check resource group
    Write-Host "Resource Group: " -NoNewline -ForegroundColor White
    $rg = az group show --name $ResourceGroup 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "EXISTS" -ForegroundColor Green
    } else {
        Write-Host "NOT FOUND" -ForegroundColor Red
    }
    
    # Check AKS cluster
    Write-Host "AKS Cluster: " -NoNewline -ForegroundColor White
    $cluster = az aks show --name $ClusterName --resource-group $ResourceGroup 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "EXISTS" -ForegroundColor Green
    } else {
        Write-Host "NOT FOUND" -ForegroundColor Red
    }
    
    # Check ACR
    Write-Host "Container Registry: " -NoNewline -ForegroundColor White
    $acr = az acr show --name $RegistryName --resource-group $ResourceGroup 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "EXISTS" -ForegroundColor Green
    } else {
        Write-Host "NOT FOUND" -ForegroundColor Red
    }
    
    # Check kubectl context
    Write-Host "kubectl Context: " -NoNewline -ForegroundColor White
    kubectl get nodes 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CONNECTED" -ForegroundColor Green
    } else {
        Write-Host "NOT CONNECTED" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Main execution
switch ($Scope) {
    "app" {
        Remove-Application
        Show-Status
    }
    "cluster" {
        Remove-Cluster
        Show-Status
    }
    "all" {
        Remove-Everything
        Show-Status
    }
    "help" {
        Show-Help
        Show-Status
    }
    default {
        Show-Help
        Show-Status
    }
}
