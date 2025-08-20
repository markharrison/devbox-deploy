 
Write-Host "Starting Deployment Environments Setup ..." -ForegroundColor Cyan

. "$PSScriptRoot\params.ps1"

. "$PSScriptRoot\auth1.ps1"

# --------------------------------------------------------------------
# Capture Dev Center Managed Identity (enable & wait if missing)
# --------------------------------------------------------------------
$DevCenterId = az devcenter admin devcenter show -n $DevCenterName -g $ResourceGroup --query id -o tsv
$DevCenterMI = az resource show --ids $DevCenterId --query identity.principalId -o tsv
if (-not $DevCenterMI) {
    Write-Host "No managed identity found for $DevCenterName; enabling SystemAssigned identity..." -ForegroundColor Cyan
    az resource update --ids $DevCenterId --set identity.type=SystemAssigned -o none
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to request enabling managed identity. Check permissions." -ForegroundColor Red; exit 1 }

    Write-Host "Waiting for DevCenter resource update to complete..." -ForegroundColor Cyan
    az resource wait --ids $DevCenterId --updated --interval 5 --timeout 300
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ Timed out waiting for DevCenter update. Inspect in portal." -ForegroundColor Red; exit 1 }

    $DevCenterMI = az resource show --ids $DevCenterId --query identity.principalId -o tsv
    if (-not $DevCenterMI) { Write-Host "❌ Managed identity principalId still missing after wait. Try again later." -ForegroundColor Red; exit 1 }

    Write-Host "$([char]0x2713) Managed identity created for ${DevCenterName}: ${DevCenterMI}" -ForegroundColor Green
}
else {
    Write-Host "$([char]0x2713) Managed identity found for ${DevCenterName}: ${DevCenterMI}" -ForegroundColor Yellow
}

# --------------------------------------------------------------------
# Assign Roles to Dev Center Identity
# --------------------------------------------------------------------
Write-Host "Assigning Contributor role to DevCenter managed identity ($DevCenterMI) at subscription scope..." -ForegroundColor Cyan
az role assignment create --assignee-object-id $DevCenterMI --assignee-principal-type ServicePrincipal --role "Contributor" --scope "/subscriptions/$SubscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to assign Contributor role to DevCenter identity ($DevCenterMI). Check permissions and try again." -ForegroundColor Red; exit 1 }

Write-Host "Assigning User Access Administrator role to DevCenter managed identity ($DevCenterMI) at subscription scope..." -ForegroundColor Cyan
az role assignment create --assignee-object-id $DevCenterMI --assignee-principal-type ServicePrincipal --role "User Access Administrator" --scope "/subscriptions/$SubscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to assign User Access Administrator role to DevCenter identity ($DevCenterMI). Check permissions and try again." -ForegroundColor Red; exit 1 }

Write-Host "$([char]0x2713) Role assignment complete." -ForegroundColor Green


# --------------------------------------------------------------------
# DevCenter-level Environment Type
# --------------------------------------------------------------------

Write-Host "Preparing roles JSON (Contributor) for environment-type operations..." -ForegroundColor Cyan
# Build roles JSON once (role GUID required by the service)
$ContribRoleGuid = az role definition list --name "Contributor" --query "[0].name" -o tsv
if ($LASTEXITCODE -ne 0 -or -not $ContribRoleGuid) { Write-Host "❌ Failed to lookup Contributor role GUID; cannot proceed." -ForegroundColor Red; exit 1 }
$rolesJson = "{`"$ContribRoleGuid`":{}}"

Write-Host "Creating Dev Center environment type '$EnvironmentName'..." -ForegroundColor Cyan
$DevEnvExists = az devcenter admin environment-type show -n "$EnvironmentName" --resource-group $ResourceGroup --dev-center-name $DevCenterName --query id -o tsv 2>$null
if ($DevEnvExists) {
    Write-Host "$([char]0x2713) Dev Center environment type '$EnvironmentName' already exists." -ForegroundColor Yellow
}
else {
    az devcenter admin environment-type create --name "$EnvironmentName" --resource-group $ResourceGroup --dev-center-name $DevCenterName | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: environment-type create (DevCenter scope)." -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Dev Center environment type '$EnvironmentName' created." -ForegroundColor Green
}

# --------------------------------------------------------------------
# Project-level Environment Type
# --------------------------------------------------------------------
Write-Host "Creating Project-level Environment Type $EnvironmentName ..." -ForegroundColor Cyan
$ProjEnvExists = az devcenter admin project-environment-type show -n "$EnvironmentName" --project $ProjectName -g $ResourceGroup --query id -o tsv 2>$null
if ($ProjEnvExists) {
    Write-Host "$([char]0x2713) Project-level environment type $EnvironmentName already exists." -ForegroundColor Yellow
}
else {
    # The AZ CLI now requires an --identity-type for project-level environment types.
    # Use SystemAssigned by default; adjust if you need UserAssigned or None.
    az devcenter admin project-environment-type create --name "$EnvironmentName" --project $ProjectName -g $ResourceGroup --roles "$rolesJson" --deployment-target-id "/subscriptions/$SubscriptionId" --identity-type SystemAssigned --status Enabled | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ AZ command failed: project-environment-type create (Project scope)" -ForegroundColor Red; exit 1 }
    Write-Host "$([char]0x2713) Project-level environment type $EnvironmentName created." -ForegroundColor Green
}


# --------------------------------------------------------------------
# Assign Project Roles to User
# --------------------------------------------------------------------
Write-Host "Giving user 'Deployment Environments User' role at subscription scope..." -ForegroundColor Cyan
az role assignment create --assignee "$UserPrincipalName" --role "Deployment Environments User" --scope "/subscriptions/$SubscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to assign 'Deployment Environments User' to $UserPrincipalName. Check permissions and try again." -ForegroundColor Red; exit 1 }
Write-Host "$([char]0x2713) Assigned 'Deployment Environments User' role to $UserPrincipalName" -ForegroundColor Green

Write-Host "Optionally assigning 'DevCenter Project Admin' role to user at subscription scope (for testing/admin tasks)..." -ForegroundColor Cyan
az role assignment create --assignee "$UserPrincipalName" --role "DevCenter Project Admin" --scope "/subscriptions/$SubscriptionId" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to assign 'DevCenter Project Admin' to $UserPrincipalName. Check permissions and try again." -ForegroundColor Red; exit 1 }
Write-Host "$([char]0x2713) Assigned 'DevCenter Project Admin' role to $UserPrincipalName" -ForegroundColor Green

# --------------------------------------------------------------------
Write-Host "$([char]0x2713) Setup complete. Dev Center: $DevCenterName, Project: $ProjectName, Environment: $EnvironmentName"  -ForegroundColor Green

# List DevCenter-level environment types
# Write-Host "Listing Dev Center environment types for DevCenter '$DevCenterName' in RG '$ResourceGroup'..." -ForegroundColor Cyan
# az devcenter admin environment-type list --resource-group $ResourceGroup --dev-center-name $DevCenterName -o table
# if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to list Dev Center environment types"; exit 1 }

# # Show details for the environment type (DevCenter scope)
# Write-Host "Showing Dev Center environment-type '$EnvironmentName' details..." -ForegroundColor Cyan
# az devcenter admin environment-type show --name $EnvironmentName --resource-group $ResourceGroup --dev-center-name $DevCenterName -o json
# if ($LASTEXITCODE -ne 0) { Write-Host "⚠️ DevCenter-level environment-type '$EnvironmentName' not found or access denied." -ForegroundColor Yellow }

# # List Project-level environment types
# Write-Host "Listing Project-level environment types for Project '$ProjectName'..." -ForegroundColor Cyan
# az devcenter admin project-environment-type list --project $ProjectName -g $ResourceGroup -o table
# if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to list project-level environment types"; exit 1 }

# # Show details for the project-level environment type
# Write-Host "Showing Project-level environment-type '$EnvironmentName' details..." -ForegroundColor Cyan
# az devcenter admin project-environment-type show --name $EnvironmentName --project $ProjectName -g $ResourceGroup -o json
# if ($LASTEXITCODE -ne 0) { Write-Host "⚠️ Project-level environment-type '$EnvironmentName' not found or access denied." -ForegroundColor Yellow }