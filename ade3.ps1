
. "$PSScriptRoot\params.ps1"

az devcenter admin catalog list --dev-center-name $DevCenterName --resource-group $ResourceGroup --output table
