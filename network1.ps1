Write-Host "Networking setup ..." -ForegroundColor Cyan

Write-Host "Creating VNet $VNetName ..." -ForegroundColor Cyan
$vnetExists = az network vnet show --resource-group $ResourceGroup --name $VNetName --query id -o tsv 2>$null
if ($vnetExists) {
	Write-Host "$([char]0x2713) VNet $VNetName already exists." -ForegroundColor Yellow
} else {
	az network vnet create --resource-group $ResourceGroup --name $VNetName --location $Location --address-prefixes $AddressPrefix --subnet-name $SubnetName --subnet-prefixes $SubnetPrefix | Out-Null
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: vnet create" -ForegroundColor Red; exit 1 }
	Write-Host "$([char]0x2713) VNet $VNetName created." -ForegroundColor Green
}

Write-Host "Creating subnet $SubnetName ..." -ForegroundColor Cyan
$subnetExists = az network vnet subnet show --resource-group $ResourceGroup --vnet-name $VNetName --name $SubnetName --query id -o tsv 2>$null
if ($subnetExists) {
	Write-Host "$([char]0x2713) Subnet $SubnetName already exists." -ForegroundColor Yellow
	$SubnetId = $subnetExists
} else {
	az network vnet subnet create --resource-group $ResourceGroup --vnet-name $VNetName --name $SubnetName --address-prefixes $SubnetPrefix | Out-Null
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: subnet create" -ForegroundColor Red; exit 1 }
	$SubnetId = az network vnet subnet show --resource-group $ResourceGroup --vnet-name $VNetName --name $SubnetName --query id -o tsv 2>$null
	if ($LASTEXITCODE -ne 0 -or -not $SubnetId) { Write-Host "\u274c AZ command failed: subnet show" -ForegroundColor Red; exit 1 }
	Write-Host "$([char]0x2713) Subnet $SubnetName created." -ForegroundColor Green
}

Write-Host "Creating Public IP Address $PublicIpName ..." -ForegroundColor Cyan

$publicIpExists = az network public-ip show -g $ResourceGroup -n $PublicIpName --query id -o tsv 2>$null
if ($publicIpExists) {
	Write-Host "$([char]0x2713) Public IP $PublicIpName already exists." -ForegroundColor Yellow
	$PublicIpId = $publicIpExists
} else {
	az network public-ip create -g $ResourceGroup -n $PublicIpName --sku Standard --allocation-method Static --location $Location | Out-Null
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: public-ip create" -ForegroundColor Red; exit 1 }

	az network public-ip wait --name $PublicIpName --resource-group $ResourceGroup --created --timeout 120 2>$null
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed or timed out: public-ip wait" -ForegroundColor Red; exit 1 }

	$PublicIpId = az network public-ip show -g $ResourceGroup -n $PublicIpName --query id -o tsv
	if ($LASTEXITCODE -ne 0 -or -not $PublicIpId) { Write-Host "\u274c Failed to retrieve Public IP id after wait" -ForegroundColor Red; exit 1 }
	Write-Host "$([char]0x2713) Public IP Address created: $PublicIpId" -ForegroundColor Green
}

Write-Host "Creating NAT Gateway $NatGatewayName ..." -ForegroundColor Cyan
$natExists = az network nat gateway show --resource-group $ResourceGroup --name $NatGatewayName --query id -o tsv 2>$null
if ($natExists) {
	Write-Host "$([char]0x2713) NAT Gateway $NatGatewayName already exists." -ForegroundColor Yellow
	$NatGatewayId = $natExists
} else {
	$NatGatewayId = az network nat gateway create -g $ResourceGroup -n $NatGatewayName --public-ip-addresses $PublicIpId --idle-timeout 10 --location $Location --query id -o tsv
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: nat gateway create" -ForegroundColor Red; exit 1 }
	Write-Host "$([char]0x2713) NAT Gateway created: $NatGatewayId" -ForegroundColor Green
}

Write-Host "Update Subnet $SubnetName with NAT Gateway $NatGatewayName ..." -ForegroundColor Cyan

# Inspect current subnet and its natGateway (if any)
$subnetOut = az network vnet subnet show -g $ResourceGroup --vnet-name $VNetName --name $SubnetName -o json 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: subnet show; output: $subnetOut" -ForegroundColor Red; exit 1 }
try { $subnetObj = $subnetOut | ConvertFrom-Json } catch { Write-Host "\u274c Failed to parse subnet show output: $subnetOut" -ForegroundColor Red; exit 1 }

$existingNatId = $null
if ($subnetObj.natGateway) { $existingNatId = $subnetObj.natGateway.id }

if ($existingNatId) {
	# If NAT gateway already associated
	if ($NatGatewayId -and ($existingNatId -eq $NatGatewayId)) {
		Write-Host "$([char]0x2713) Subnet $SubnetName already associated with NAT Gateway $NatGatewayName" -ForegroundColor Yellow
		$UpdatedSubnetId = $subnetObj.id
	} else {
		Write-Host "Subnet $SubnetName is associated with a different NAT Gateway; updating to $NatGatewayName ..." -ForegroundColor Yellow
		$UpdatedSubnetId = az network vnet subnet update -g $ResourceGroup --vnet-name $VNetName --name $SubnetName --nat-gateway $NatGatewayName --query id -o tsv
		if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: subnet update" -ForegroundColor Red; exit 1 }
		Write-Host "$([char]0x2713) Subnet updated: $UpdatedSubnetId" -ForegroundColor Green
	}
} else {
	# No NAT gateway currently attached, perform the update
	$UpdatedSubnetId = az network vnet subnet update -g $ResourceGroup --vnet-name $VNetName --name $SubnetName --nat-gateway $NatGatewayName --query id -o tsv
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: subnet update" -ForegroundColor Red; exit 1 }
	Write-Host "$([char]0x2713) Subnet updated: $UpdatedSubnetId" -ForegroundColor Green
}


Write-Host "Creating Network Connection $NetworkConnectionName ..." -ForegroundColor Cyan
if (-not (az devcenter admin network-connection show --name $NetworkConnectionName --resource-group $ResourceGroup --query id -o tsv 2>$null)) {
	az devcenter admin network-connection create --name $NetworkConnectionName --resource-group $ResourceGroup --location $Location --domain-join-type $DomainJoinType --subnet-id $SubnetId | Out-Null
	if ($LASTEXITCODE -ne 0) { Write-Host "\u274c AZ command failed: network-connection create" -ForegroundColor Red; exit 1 }
	Write-Host "$([char]0x2713) Network Connection creation started; may take a few minutes to provision." -ForegroundColor Green
} else {
	Write-Host "$([char]0x2713) Network Connection already exists: $NetworkConnectionName" -ForegroundColor Yellow
}

