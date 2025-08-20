. "$PSScriptRoot\params.ps1"
Write-Host "Deleting Resource Group $ResourceGroup ..." -ForegroundColor Cyan
az group delete --name $ResourceGroup --yes --no-wait
