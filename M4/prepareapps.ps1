param(
   [string] [Parameter(Mandatory = $true)] $ClusterName,
   [string] $RegionShortName = "westeurope"
)

. "$PSScriptRoot\..\Common.ps1"

CheckLoggedIn

# get current context information to simplify calling the main script
$azureContext = Get-AzureRmContext
$tenantId = $azureContext.Tenant.Id
$replyUrl = "https://$ClusterName.$RegionShortName.cloudapp.azure.com:19080/Explorer/index.html"

Write-Host "Invoking official script for"
Write-Host "  tenant: $tenantId"
Write-Host "  replyUrl: $replyUrl"
& $PSScriptRoot\AADTool\SetupApplications.ps1 -TenantId $tenantId `
    -ClusterName $ClusterName `
    -WebApplicationReplyUrl $replyUrl

