# Cleanup Obsolete Project Files
# This script removes old and redundant files from the JumpingFox project

Write-Host "🧹 Cleaning up obsolete JumpingFox project files..." -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Files to remove
$filesToRemove = @(
    # Obsolete PowerShell scripts
    "deploy.ps1",
    "deploy-cli.ps1", 
    "deploy-debug.ps1",
    "test-rate-limits.ps1",
    "setup-aks-tools.ps1",
    "fix-openapi-spec.ps1",
    
    # Obsolete JSON files (App Service related)
    "azure-deploy.json",
    "azure-deploy-simple.json",
    "azure-deploy.parameters.json",
    "current-swagger.json"
)

$removedCount = 0
$notFoundCount = 0

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Write-Host "🗑️  Removing: $file" -ForegroundColor Yellow
        Remove-Item $file -Force
        $removedCount++
    } else {
        Write-Host "⚠️  Not found: $file" -ForegroundColor Gray
        $notFoundCount++
    }
}

# Clean up any temporary files that might exist
$tempFiles = @(
    "swagger.json",
    "swagger-clean.json", 
    "swagger-fixed.json",
    "api-policy.xml"
)

Write-Host ""
Write-Host "🧹 Cleaning temporary files..." -ForegroundColor Yellow
foreach ($tempFile in $tempFiles) {
    if (Test-Path $tempFile) {
        Write-Host "🗑️  Removing temp file: $tempFile" -ForegroundColor Yellow
        Remove-Item $tempFile -Force
        $removedCount++
    }
}

# Summary
Write-Host ""
Write-Host "✅ Cleanup completed!" -ForegroundColor Green
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   • Files removed: $removedCount" -ForegroundColor White
Write-Host "   • Files not found: $notFoundCount" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Remaining essential files:" -ForegroundColor Cyan
Write-Host "   PowerShell Scripts:" -ForegroundColor Yellow
Write-Host "   • deploy-aks.ps1 (AKS deployment)" -ForegroundColor White
Write-Host "   • setup-apim.ps1 (APIM integration)" -ForegroundColor White  
Write-Host "   • get-apim-key.ps1 (API testing)" -ForegroundColor White
Write-Host "   • cleanup-aks.ps1 (resource cleanup)" -ForegroundColor White
Write-Host "   • test-apim-rate-limits.ps1 (rate limit testing)" -ForegroundColor White
Write-Host ""
Write-Host "   Configuration Files:" -ForegroundColor Yellow
Write-Host "   • appsettings.json" -ForegroundColor White
Write-Host "   • appsettings.Development.json" -ForegroundColor White
Write-Host "   • Properties/launchSettings.json" -ForegroundColor White
Write-Host ""
Write-Host "   Other Files:" -ForegroundColor Yellow
Write-Host "   • apim-policies-samples.xml (APIM policy examples)" -ForegroundColor White
Write-Host "   • APIM-INTEGRATION-GUIDE.md (documentation)" -ForegroundColor White
Write-Host "   • All C# source files and project files" -ForegroundColor White
