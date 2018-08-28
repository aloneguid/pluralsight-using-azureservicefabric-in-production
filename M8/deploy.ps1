param(
   [string] [Parameter(Mandatory = $true)] $Name,
   [string] [Parameter(Mandatory = $true)] $VaultResourceId,
   [string] [Parameter(Mandatory = $true)] $CertUrlValue,
   [string] [Parameter(Mandatory = $true)] $CertThumbprint,
   [string] [Parameter(Mandatory = $true)] $TenantId,
   [string] [Parameter(Mandatory = $true)] $ClusterApplicationId,
   [string] [Parameter(Mandatory = $true)] $ClientApplicationId
)

. "$PSScriptRoot\..\Common.ps1"

$ResourceGroupName = "ASF-$Name"  # Resource group everything will be created in
$rdpPassword = "Password00;;"

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

Write-Host "Applying cluster template..."
Write-Host "  vault resource id: $VaultResourceId"
Write-Host "  cert url value:    $CertUrlValue"

$armParameters = @{
    namePart = $Name;
    certificateThumbprint = $CertThumbprint;
    sourceVaultResourceId = $VaultResourceId;
    certificateUrlValue = $CertUrlValue;
    rdpPassword = $rdpPassword;
    vmInstanceCount = 3;
    durabilityLevel = "Bronze";
    reliabilityLevel = "Bronze";
    aadTenantId = $TenantId;
    aadClusterApplicationId = $ClusterApplicationId;
    aadClientApplicationId = $ClientApplicationId;
  }

New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\servicefabric.json" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose