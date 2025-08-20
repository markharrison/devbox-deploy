# Dev Box Setup Parameters
Write-Host "Initialise Parameters ..." -ForegroundColor Cyan

$SubscriptionId = "bf0ff2fe-5503-48b0-8b52-cd0e67aa8fd8"
$Location       = "uksouth"
$prefix         = "marka"
$ResourceGroup  = "${prefix}devbox-rg"
$DevCenterName  = "${prefix}DevCenter"
$ProjectName    = "${prefix}DevProject"
$DevDefName     = "${prefix}DevBoxDefinition"
$PoolName       = "${prefix}DevBoxPool"
$GalleryName    = "default"
$EnvironmentName = "DevPlayPen"
$CatalogName    = "QuickStartCatalog"
$CatalogUrl     = "https://github.com/microsoft/devcenter-catalog.git"
$SkuName        = "general_i_8c32gb1024ssd_v2"    # "general_i_32c128gb1024ssd_v2"
$ImageName      = "microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2"
$OsStorageType  = "ssd_1024gb"
$ImageReferenceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DevCenter/devcenters/$DevCenterName/galleries/$GalleryName/images/$ImageName"
$UserPrincipalName = "mark@markharrison.org"

$UseManagedNetwork = $true
$NetworkConnectionName = "${prefix}devbox-netconn"
$VNetName       = "${prefix}devbox-vnet"
$SubnetName     = "${prefix}devbox-subnet"
$AddressPrefix  = "10.80.0.0/16"
$SubnetPrefix   = "10.80.0.0/24"
$DomainJoinType = "AzureADJoin"
$PublicIpName = "${prefix}-nat-pip"
$NatGatewayName = "${prefix}-nat-gw"

Write-Host "DevCenter: $DevCenterName  Location: $Location" -ForegroundColor Cyan