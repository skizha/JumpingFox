# Fix OpenAPI Specification for APIM Import
# This script cleans up the OpenAPI specification to make it compatible with APIM

param(
    [string]$InputFile = "current-swagger.json",
    [string]$OutputFile = "swagger-fixed.json",
    [string]$AksServiceUrl = "http://134.33.206.69"
)

Write-Host "🔧 Fixing OpenAPI Specification for APIM Compatibility" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Download latest spec if input file doesn't exist
if (-not (Test-Path $InputFile)) {
    Write-Host "Downloading latest OpenAPI spec from AKS service..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "$AksServiceUrl/swagger/v1/swagger.json" -OutFile $InputFile
        Write-Host "✅ Downloaded OpenAPI specification" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to download OpenAPI spec from $AksServiceUrl" -ForegroundColor Red
        exit 1
    }
}

# Read the OpenAPI specification
try {
    Write-Host "Reading OpenAPI specification..." -ForegroundColor Yellow
    $openApiSpec = Get-Content $InputFile -Raw | ConvertFrom-Json
    Write-Host "✅ OpenAPI spec loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to parse OpenAPI specification: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Fix issues
$fixesApplied = 0

Write-Host ""
Write-Host "🔍 Analyzing and fixing issues..." -ForegroundColor Yellow

# Issue 1: Fix invalid schema names
if ($openApiSpec.components -and $openApiSpec.components.schemas) {
    $problematicSchemas = @()
    
    $openApiSpec.components.schemas.PSObject.Properties | ForEach-Object {
        $schemaName = $_.Name
        
        # Check for invalid characters in schema names
        if ($schemaName -match '[<>]|f__AnonymousType|\s|[^a-zA-Z0-9\.\-_]') {
            $problematicSchemas += $schemaName
        }
    }
    
    if ($problematicSchemas.Count -gt 0) {
        Write-Host "Found $($problematicSchemas.Count) problematic schema(s):" -ForegroundColor Yellow
        foreach ($schema in $problematicSchemas) {
            Write-Host "  ❌ $schema" -ForegroundColor Red
            
            # Remove the problematic schema
            $openApiSpec.components.schemas.PSObject.Properties.Remove($schema)
            $fixesApplied++
        }
        Write-Host "✅ Removed $($problematicSchemas.Count) problematic schema(s)" -ForegroundColor Green
    } else {
        Write-Host "✅ No problematic schema names found" -ForegroundColor Green
    }
}

# Issue 2: Ensure all required fields are present
if (-not $openApiSpec.info.title) {
    $openApiSpec.info.title = "JumpingFox API"
    $fixesApplied++
    Write-Host "✅ Added missing API title" -ForegroundColor Green
}

if (-not $openApiSpec.info.version) {
    $openApiSpec.info.version = "1.0.0"
    $fixesApplied++
    Write-Host "✅ Added missing API version" -ForegroundColor Green
}

# Issue 3: Clean up any null or empty values that might cause issues
function Remove-EmptyProperties($obj) {
    if ($obj -is [PSCustomObject]) {
        $propsToRemove = @()
        $obj.PSObject.Properties | ForEach-Object {
            if ($null -eq $_.Value -or ($_.Value -is [string] -and [string]::IsNullOrWhiteSpace($_.Value))) {
                $propsToRemove += $_.Name
            } elseif ($_.Value -is [PSCustomObject] -or $_.Value -is [array]) {
                Remove-EmptyProperties $_.Value
            }
        }
        foreach ($prop in $propsToRemove) {
            $obj.PSObject.Properties.Remove($prop)
        }
    } elseif ($obj -is [array]) {
        for ($i = 0; $i -lt $obj.Count; $i++) {
            Remove-EmptyProperties $obj[$i]
        }
    }
}

Write-Host "🧹 Cleaning empty properties..." -ForegroundColor Yellow
Remove-EmptyProperties $openApiSpec
Write-Host "✅ Cleaned empty properties" -ForegroundColor Green

# Save the fixed specification
try {
    Write-Host ""
    Write-Host "💾 Saving fixed OpenAPI specification..." -ForegroundColor Yellow
    
    $fixedJson = $openApiSpec | ConvertTo-Json -Depth 20
    $fixedJson | Out-File $OutputFile -Encoding UTF8
    
    Write-Host "✅ Fixed OpenAPI specification saved to: $OutputFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to save fixed specification: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Validate the fixed specification
Write-Host ""
Write-Host "🔍 Validating fixed specification..." -ForegroundColor Yellow

try {
    $fixedSpec = Get-Content $OutputFile -Raw | ConvertFrom-Json
    
    # Basic validation
    $endpointCount = $fixedSpec.paths.PSObject.Properties.Count
    $schemaCount = if ($fixedSpec.components.schemas) { $fixedSpec.components.schemas.PSObject.Properties.Count } else { 0 }
    
    Write-Host "✅ Validation successful:" -ForegroundColor Green
    Write-Host "  📊 API Title: $($fixedSpec.info.title)" -ForegroundColor White
    Write-Host "  📊 API Version: $($fixedSpec.info.version)" -ForegroundColor White
    Write-Host "  📊 OpenAPI Version: $($fixedSpec.openapi)" -ForegroundColor White
    Write-Host "  📊 Endpoints: $endpointCount" -ForegroundColor White
    Write-Host "  📊 Schemas: $schemaCount" -ForegroundColor White
}
catch {
    Write-Host "⚠️  Validation warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "🎉 OpenAPI Specification Fix Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host "  🔧 Fixes Applied: $fixesApplied" -ForegroundColor White
Write-Host "  📁 Input File: $InputFile" -ForegroundColor White
Write-Host "  📁 Output File: $OutputFile" -ForegroundColor White
Write-Host ""

if ($fixesApplied -gt 0) {
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Use the fixed file for APIM import: $OutputFile" -ForegroundColor White
    Write-Host "  2. Re-run the APIM setup script" -ForegroundColor White
    Write-Host "  3. Or manually import using:" -ForegroundColor White
    Write-Host "     az apim api import --specification-path $OutputFile ..." -ForegroundColor Gray
} else {
    Write-Host "✅ No fixes were needed - your OpenAPI spec is already compliant!" -ForegroundColor Green
}

Write-Host ""
