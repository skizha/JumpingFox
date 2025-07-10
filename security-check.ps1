# Security Check for JumpingFox Repository
# This script checks for hardcoded sensitive values before publishing

Write-Host "🔐 JumpingFox Security Check" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$issues = @()
$warnings = @()

# Check for sensitive patterns in PowerShell scripts
$psFiles = Get-ChildItem -Path "." -Filter "*.ps1" -Recurse | Where-Object { $_.Name -ne "security-check.ps1" }

foreach ($file in $psFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Check for email addresses
    if ($content -match "[\w\.-]+@[\w\.-]+\.\w+") {
        if ($content -notmatch "your-email@example\.com" -and $content -notmatch "admin@example\.com") {
            $issues += "Email address found in $($file.Name)"
        }
    }
    
    # Check for subscription IDs (GUID pattern)
    if ($content -match "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}") {
        $issues += "Potential subscription ID found in $($file.Name)"
    }
    
    # Check for subscription keys (32+ char alphanumeric)
    if ($content -match "\b[a-zA-Z0-9]{32,}\b") {
        if ($content -notmatch "your-subscription-key-here") {
            $issues += "Potential subscription key found in $($file.Name)"
        }
    }
    
    # Check for IP addresses
    if ($content -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b") {
        if ($content -notmatch "127\.0\.0\.1" -and $content -notmatch "localhost") {
            $warnings += "IP address found in $($file.Name) - verify it's not sensitive"
        }
    }
}

# Check for config.json (should not exist in repo)
if (Test-Path "config.json") {
    $issues += "config.json file exists - this should not be committed"
}

# Check if .gitignore exists and has proper entries
if (-not (Test-Path ".gitignore")) {
    $issues += ".gitignore file missing"
} else {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    $requiredEntries = @("config.json", "*.config.json", "subscription-keys.txt", "azure-credentials.json")
    
    foreach ($entry in $requiredEntries) {
        if ($gitignoreContent -notmatch [regex]::Escape($entry)) {
            $warnings += "Missing .gitignore entry: $entry"
        }
    }
}

# Check for template file
if (-not (Test-Path "config.template.json")) {
    $warnings += "config.template.json not found - users won't have a template"
}

# Results
Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "✅ No security issues found!" -ForegroundColor Green
} else {
    Write-Host "❌ Security issues found:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "   • $issue" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   • $warning" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📋 Pre-publish checklist:" -ForegroundColor Cyan
Write-Host "   ✅ Remove all sensitive hardcoded values" -ForegroundColor White
Write-Host "   ✅ Create config.template.json with placeholders" -ForegroundColor White
Write-Host "   ✅ Update .gitignore to exclude config.json" -ForegroundColor White
Write-Host "   ✅ Update README with security instructions" -ForegroundColor White
Write-Host "   ✅ Test configuration loading in all scripts" -ForegroundColor White
Write-Host "   ✅ Run this security check" -ForegroundColor White

if ($issues.Count -eq 0) {
    Write-Host ""
    Write-Host "🚀 Repository is ready for public publishing!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "🔒 Fix security issues before publishing!" -ForegroundColor Red
}
