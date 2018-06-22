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
$rdpPassword = "Password00;;"

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

# Ensure resource group we are deploying to exists.
EnsureResourceGroup $ResourceGroupName $Location

# Ensure that the Key Vault resource exists.
$keyVault = EnsureKeyVault $KeyVaultName $ResourceGroupName $Location

# Ensure that self-signed certificate is created and imported into Key Vault
$cert = EnsureSelfSignedCertificate $KeyVaultName $Name

Write-Host "Applying cluster template..."
$armParameters = @{
    namePart = $Name;
    certificateThumbprint = $cert.Thumbprint;
    sourceVaultResourceId = $keyVault.ResourceId;
    certificateUrlValue = $cert.SecretId;
    rdpPassword = $rdpPassword;
    vmInstanceCount = 5;
    aadTenantId = $TenantId;
    aadClusterApplicationId = $ClusterApplicationId;
    aadClientApplicationId = $ClientApplicationId;
  }

New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\production.json" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose