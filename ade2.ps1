. "$PSScriptRoot\params.ps1"

Write-Host "Add Microsoft Catalog $CatalogName at Dev Center Level ..." -ForegroundColor Cyan

$CatalogId = az devcenter admin catalog show --dev-center-name $DevCenterName --resource-group $ResourceGroup --name $CatalogName --query id -o tsv 2>$null
if ($LASTEXITCODE -ne 0) { $CatalogId = $null }

if ($CatalogId) {
    Write-Host "$([char]0x2713) Microsoft '$CatalogName' already exists at Dev Center Level." -ForegroundColor Yellow
} else {
    Write-Host "Creating Microsoft Catalog '$CatalogName' at Dev Center Level ..." -ForegroundColor Cyan
    $GitHubArg = "{'uri': '$CatalogUrl', 'branch': 'main', 'path': '/Environment-Definitions'}"
    az devcenter admin catalog create --dev-center-name $DevCenterName --resource-group $ResourceGroup --name $CatalogName --git-hub $GitHubArg --sync-type Scheduled 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: catalog create" -ForegroundColor Red; exit 1 }
    $CatalogId = az devcenter admin catalog show --dev-center-name $DevCenterName --resource-group $ResourceGroup --name $CatalogName --query id -o tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $CatalogId) { Write-Host "❌ AZ command failed: catalog show (id) after create" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Microsoft $CatalogName added at Dev Center Level." -ForegroundColor Green
}

Write-Host "CatalogId: $CatalogId" -ForegroundColor Cyan

