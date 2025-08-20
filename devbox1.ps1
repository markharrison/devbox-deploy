. "$PSScriptRoot\params.ps1"

Write-Host "Starting Dev Center setup..." -ForegroundColor Cyan

. "$PSScriptRoot\auth1.ps1"

. "$PSScriptRoot\createRG1.ps1"

if ($UseManagedNetwork) {
    Write-Host "$([char]0x2713) Skipping network setup because UseManagedNetwork = $UseManagedNetwork" -ForegroundColor Yellow
}
else {
    . "$PSScriptRoot\network1.ps1"
}

Write-Host "Creating Dev Center $DevCenterName ..." -ForegroundColor Cyan
if (-not (az devcenter admin devcenter show --name $DevCenterName --resource-group $ResourceGroup --query id -o tsv 2>$null)) {
    az devcenter admin devcenter create --name $DevCenterName --resource-group $ResourceGroup --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: devcenter create" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Dev Center created." -ForegroundColor Green
}
else {
    Write-Host "$([char]0x2713) Dev Center already exists." -ForegroundColor Yellow
}

Write-Host "Creating Project $ProjectName ..." -ForegroundColor Cyan
$DevCenterId = az devcenter admin devcenter show --name $DevCenterName --resource-group $ResourceGroup --query id -o tsv
$ProjectExists = az devcenter admin project show --name $ProjectName --resource-group $ResourceGroup --query id -o tsv 2>$null
if (-not $ProjectExists) {
    az devcenter admin project create --name $ProjectName --resource-group $ResourceGroup --dev-center-id $DevCenterId --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: project create" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Project created." -ForegroundColor Green
}
else {
    Write-Host "$([char]0x2713) Project already exists." -ForegroundColor Yellow
}

Write-Host "Creating Dev Box Definition $DevDefName ..." -ForegroundColor Cyan
$DevDefExists = az devcenter admin devbox-definition show --name $DevDefName --resource-group $ResourceGroup --dev-center-name $DevCenterName --query id -o tsv 2>$null
if (-not $DevDefExists) {
    az devcenter admin devbox-definition create --name $DevDefName --resource-group $ResourceGroup --dev-center-name $DevCenterName --image-reference id=\"$ImageReferenceId\" --sku name=$SkuName --os-storage-type $OsStorageType --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: devbox-definition create" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Dev Box Definition created." -ForegroundColor Green
}
else {
    Write-Host "$([char]0x2713) Dev Box Definition already exists." -ForegroundColor Yellow
}

if ($UseManagedNetwork -eq $false) {
    . "$PSScriptRoot\network2.ps1"
}

Write-Host "Creating Pool $PoolName ..." -ForegroundColor Cyan

$PoolExists = az devcenter admin pool show --project-name $ProjectName --resource-group $ResourceGroup --name $PoolName --query id -o tsv 2>$null
if (-not $PoolExists) {

    if ($UseManagedNetwork) {
         az devcenter admin pool create --project-name $ProjectName --resource-group $ResourceGroup --name $PoolName --virtual-network-type "Managed" --managed-virtual-network-region ["$Location"]  --devbox-definition-name $DevDefName --location $Location --local-administrator Enabled  --single-sign-on-status "Enabled"  | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: pool create" -ForegroundColor Red; exit 1 }
        Write-Host "$([char]0x2713) Pool created using managed network." -ForegroundColor Green
    }else {
        az devcenter admin pool create --project-name $ProjectName --resource-group $ResourceGroup --name $PoolName --network-connection-name $NetworkConnectionName --devbox-definition-name $DevDefName --location $Location --local-administrator Enabled  --single-sign-on-status "Enabled" | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: pool create" -ForegroundColor Red; exit 1 }
        Write-Host "$([char]0x2713) Pool created and associated with Network Connection." -ForegroundColor Green
    }

}
else {
    Write-Host "$([char]0x2713) Pool already exists." -ForegroundColor Yellow
}

