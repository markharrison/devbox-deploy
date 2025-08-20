. "$PSScriptRoot\params.ps1"

Write-Host "Listing available Dev Box SKUs for location: $Location ..." -ForegroundColor Cyan

# Get all available Dev Box SKUs
$allSkus = az devcenter admin sku list --query "[?resourceType=='projects/pools']" --output json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ devcenter admin sku list failed" -ForegroundColor Red; exit 1 }

$matchedSkus = 0
foreach ($sku in $allSkus) {
    # Check if any location matches (case-insensitive)
    $locationMatch = $false
    foreach ($skuLocation in $sku.locations) {
        if ($skuLocation -like "*$Location*" -or $Location -like "*$skuLocation*") {
            $locationMatch = $true
            break
        }
    }
    
    if (-not $locationMatch) { continue }
    
    $matchedSkus++
    Write-Host "`nSKU Name: $($sku.name)" -ForegroundColor Yellow
    Write-Host "  Tier: $($sku.tier), Size: $($sku.size), Family: $($sku.family)" -ForegroundColor Cyan
    
    if ($sku.capabilities) {
        $capabilitiesText = ($sku.capabilities | ForEach-Object { "$($_.name): $($_.value)" }) -join ", "
        Write-Host "  Capabilities: $capabilitiesText" -ForegroundColor Cyan
    }    
}

if ($matchedSkus -eq 0) {
    Write-Host "$([char]0x274C) No Dev Box SKUs found for location: $Location" -ForegroundColor Red
    exit 1
}

Write-Host "`n$([char]0x2713) Total SKUs found: $matchedSkus" -ForegroundColor Green