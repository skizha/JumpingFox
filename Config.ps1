# Configuration Helper Functions for JumpingFox
# This script provides functions to load configuration safely

function Get-JumpingFoxConfig {
    param(
        [string]$ConfigPath = "config.json"
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "❌ Configuration file not found: $ConfigPath" -ForegroundColor Red
        Write-Host "📋 Please create it from template:" -ForegroundColor Yellow
        Write-Host "   1. Copy config.template.json to config.json" -ForegroundColor White
        Write-Host "   2. Update the values with your Azure details" -ForegroundColor White
        Write-Host "   3. Never commit config.json to version control" -ForegroundColor White
        throw "Configuration file not found"
    }
    
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "✅ Configuration loaded from $ConfigPath" -ForegroundColor Green
        return $config
    }
    catch {
        Write-Host "❌ Error reading configuration file: $($_.Exception.Message)" -ForegroundColor Red
        throw "Invalid configuration file"
    }
}

function Initialize-JumpingFoxConfig {
    param(
        [string]$ConfigPath = "config.json"
    )
    
    if (Test-Path $ConfigPath) {
        Write-Host "⚠️  Configuration file already exists: $ConfigPath" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Host "❌ Configuration initialization cancelled" -ForegroundColor Red
            return
        }
    }
    
    if (-not (Test-Path "config.template.json")) {
        Write-Host "❌ Template file not found: config.template.json" -ForegroundColor Red
        return
    }
    
    Copy-Item "config.template.json" $ConfigPath
    Write-Host "✅ Configuration file created: $ConfigPath" -ForegroundColor Green
    Write-Host "📋 Please edit $ConfigPath and update with your values:" -ForegroundColor Yellow
    Write-Host "   • Azure subscription ID" -ForegroundColor White
    Write-Host "   • Publisher email and name" -ForegroundColor White
    Write-Host "   • APIM gateway URL and subscription key" -ForegroundColor White
    Write-Host "   • AKS backend URL" -ForegroundColor White
}

function Test-JumpingFoxConfig {
    param(
        [string]$ConfigPath = "config.json"
    )
    
    try {
        $config = Get-JumpingFoxConfig -ConfigPath $ConfigPath
        
        Write-Host "🧪 Testing configuration..." -ForegroundColor Cyan
        
        $issues = @()
        
        # Check required fields
        if ($config.azure.subscriptionId -eq "your-subscription-id-here") {
            $issues += "Azure subscription ID not set"
        }
        
        if ($config.azure.publisherEmail -eq "your-email@example.com") {
            $issues += "Publisher email not set"
        }
        
        if ($config.apim.subscriptionKey -eq "your-subscription-key-here") {
            $issues += "APIM subscription key not set"
        }
        
        if ($config.apim.gatewayUrl -eq "https://your-apim-name.azure-api.net") {
            $issues += "APIM gateway URL not set"
        }
        
        if ($config.aks.backendUrl -eq "http://your-aks-ip-address") {
            $issues += "AKS backend URL not set"
        }
        
        if ($issues.Count -eq 0) {
            Write-Host "✅ Configuration looks good!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️  Configuration issues found:" -ForegroundColor Yellow
            foreach ($issue in $issues) {
                Write-Host "   • $issue" -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        Write-Host "❌ Configuration test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Export functions for use in other scripts
Export-ModuleMember -Function Get-JumpingFoxConfig, Initialize-JumpingFoxConfig, Test-JumpingFoxConfig
