 

Write-Host "Waiting for Network Connection to be ready..." -ForegroundColor Cyan
do {
	$NetConnStatus = az devcenter admin network-connection show --name $NetworkConnectionName --resource-group $ResourceGroup --query provisioningState -o tsv
	if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: admin network-connection show" -ForegroundColor Red; exit 1 }
	if ($NetConnStatus -ne "Succeeded") {
		Start-Sleep -Seconds 10
	}
} while ($NetConnStatus -ne "Succeeded")
Write-Host "$([char]0x2713) Network Connection is ready!" -ForegroundColor Yellow

Write-Host "Attach Network Connection $NetworkConnectionName to DevCenter $DevCenterName ..." -ForegroundColor Cyan
if (-not (az devcenter admin attached-network show --attached-network-connection-name $NetworkConnectionName --dev-center-name $DevCenterName --resource-group $ResourceGroup --query id -o tsv 2>$null)) {
	az devcenter admin attached-network create --attached-network-connection-name $NetworkConnectionName --network-connection-id "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DevCenter/NetworkConnections/$NetworkConnectionName" --dev-center-name $DevCenterName --resource-group $ResourceGroup
		if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: attached-network create" -ForegroundColor Red; exit 1 }
    
	Write-Host "Waiting for Network Connection attachment to complete..." -ForegroundColor Cyan
	do {
		$AttachStatus = az devcenter admin attached-network show --attached-network-connection-name $NetworkConnectionName --dev-center-name $DevCenterName --resource-group $ResourceGroup --query provisioningState -o tsv
			if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: attached-network show" -ForegroundColor Red; exit 1 }
		if ($AttachStatus -ne "Succeeded") {
			Start-Sleep -Seconds 10
		}
	} while ($AttachStatus -ne "Succeeded")
	Write-Host "$([char]0x2713) Network Connection attached to Dev Center." -ForegroundColor Green
}
else {
	Write-Host "$([char]0x2713) Network Connection already attached to Dev Center." -ForegroundColor Yellow
}