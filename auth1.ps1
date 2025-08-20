. "$PSScriptRoot\params.ps1"

Write-Host "Checking Azure authentication..." -ForegroundColor Cyan
try {
    $account = az account show --query id -o tsv 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $account) {
        Write-Host "Not authenticated. Logging in..." -ForegroundColor Cyan
        az login --use-device-code 
    if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: login" -ForegroundColor Red; exit 1 }
        $subid = az account show --query id -o tsv
    if ($LASTEXITCODE -ne 0 -or -not $subid) { Write-Host "\u274c AZ command failed: account show after login" -ForegroundColor Red; exit 1 }
        Write-Host "$([char]0x2713) Authenticated. SubscriptionId: $subid" -ForegroundColor Green
    }
    else {
        Write-Host "$([char]0x2713) Already authenticated." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "$([char]0x274C) Authentication failed: $_" -ForegroundColor Red
    Write-Host "❌ Authentication failed: $_" -ForegroundColor Red
    exit 1
}
az account set --subscription $SubscriptionId; if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: account set" -ForegroundColor Red; exit 1 }
