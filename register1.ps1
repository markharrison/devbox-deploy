Write-Host "Ensuring DevCenter provider registered ..." -ForegroundColor Cyan
if ((az provider show --namespace Microsoft.DevCenter --query registrationState -o tsv) -ne 'Registered') {
    az provider register --namespace Microsoft.DevCenter | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: provider register" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Registration requested; may take a minute" -ForegroundColor Yellow
}