<#
  Use this script to prepare Azure for cluster management via VSTS.
  Please note that only Name parameter is required, the other three are not in use
  however they appear in the course video so you don't forget to get those parameters ready.

  You can always automate cluster deployment even further by adding this preparation bit into VSTS
  so that you don't have to run anything locally.
#>

param(
   [string] [Parameter(Mandatory = $true)] $Name,
   [string] [Parameter(Mandatory = $true)] $TenantId,
   [string] [Parameter(Mandatory = $true)] $ClusterApplicationId,
   [string] [Parameter(Mandatory = $true)] $ClientApplicationId
)

. "$PSScriptRoot\..\Common.ps1"

$ResourceGroupName = "ASF-$Name"  # Resource group everything will be created in
$Location = "West Europe"         # Physical location of all the resources
$KeyVaultName = "$Name-vault"     # name of the Key Vault

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

# Ensure resource group we are deploying to exists.
EnsureResourceGroup $ResourceGroupName $Location

# Ensure that the Key Vault resource exists.
$keyVault = EnsureKeyVault $KeyVaultName $ResourceGroupName $Location

# Ensure that self-signed certificate is created and imported into Key Vault
$cert = EnsureSelfSignedCertificate $KeyVaultName $Name

Write-Host "Our job is done here, continue to VSTS..."
Write-Host "  vault resource id: $($keyVault.ResourceId)"
Write-Host "  cert url value: $($cert.SecretId)"