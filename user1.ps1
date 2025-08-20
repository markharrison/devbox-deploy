. "$PSScriptRoot\params.ps1"

$Scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DevCenter/projects/$ProjectName"

Write-Host "Assigning 'DevCenter Dev Box User' role to user $UserPrincipalName" -ForegroundColor Cyan
Write-Host "Scope $Scope" -ForegroundColor Cyan

$UserObjectId = az ad user show --id $UserPrincipalName --query id --output tsv 2>$null

if ($LASTEXITCODE -ne 0) {
    $errorOutput = az ad user show --id $UserPrincipalName --query id --output tsv 2>&1
    if ($errorOutput -match "does not exist|not found|No user found") {
        Write-Host "$([char]0x274C) Could not find user '$UserPrincipalName' in Azure AD." -ForegroundColor Red
        exit 1
    } else {
    Write-Host "❌ AZ ad user show failed: $errorOutput" -ForegroundColor Red
    exit 1
    }
}

if (-not $UserObjectId) {
    Write-Host "$([char]0x274C) Could not find user '$UserPrincipalName' in Azure AD." -ForegroundColor Red
    exit 1
}

Write-Host "User $UserPrincipalName,  userid $UserObjectId" -ForegroundColor Cyan

az role assignment create --assignee $UserObjectId  --role "DevCenter Dev Box User" --scope $Scope | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ role assignment create failed for user $UserPrincipalName" -ForegroundColor Red; exit 1 }

Write-Host "$([char]0x2713) Assigned 'DevCenter Dev Box User' role to $UserPrincipalName" -ForegroundColor Green
