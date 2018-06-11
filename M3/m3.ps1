param(
   [string] [Parameter(Mandatory = $true)] $Name
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

if($false){
Write-Host "Applying cluster template..."
$armParameters = @{
    namePart = $Name;
    certificateThumbprint = $cert.Thumbprint;
    sourceVaultResourceId = $keyVault.ResourceId;
    certificateUrlValue = $cert.SecretId;
    rdpPassword = $rdpPassword;
    vmInstanceCount = 5;
  }
New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\production.json" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose
}

Write-Host "Applying Application Gateway ARM template..."
$armParameters = @{
  namePart = $Name;
}
New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\appGateway.json" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose

# NOTES
# for VM sizes see https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
# to get the list of all available locations call Get-AzureRmLocation