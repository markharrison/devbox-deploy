. "$PSScriptRoot\params.ps1"

Write-Host "Creating resource group: $ResourceGroup ..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroup | Select-String -Pattern 'True' -Quiet
if ($rgExists) {
    Write-Host "$([char]0x2713) Resource group already exists." -ForegroundColor Yellow
}
else {
    az group create --name $ResourceGroup --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: group create" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Resource group created." -ForegroundColor Green
}