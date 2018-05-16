param(
   [string] [Parameter(Mandatory = $true)] $Name
)

. "$PSScriptRoot\..\Common.ps1"

$ResourceGroupName = "PS-M2-$Name"  # Resource group everything will be created in
$Location = "West Europe"           # Physical location of all the resources
$KeyVaultName = "$Name-psm2vault"   # name of the Key Vault

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

# Ensure resource group we are deploying to exists.
EnsureResourceGroup $ResourceGroupName $Location

# Ensure that the Key Vault resource exists.
$keyVault = EnsureKeyVault $KeyVaultName $ResourceGroupName $Location

# For development purposes, we create a self-signed cluster certificate here. 
$certThumbprint, $certPassword, $certPath = CreateSelfSignedCertificate $Name

# Import the certificate into Key Vault
$kvCert = ImportCertificateIntoKeyVault $KeyVaultName $Name $certPath $certPassword

exit

Write-Host "Deploying cluster with ARM template..."
$armParameters = @{
    namePart = $Name;
    certificateThumbprint = $certThumbprint;
    sourceVaultResourceId = $keyVault.ResourceId;
    certificateUrlValue = $kvCert.SecretId;
    rdpPassword = GeneratePassword;
  }

New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $ResourceGroupName `
  -TemplateFile "$PSScriptRoot\minimal.json" `
  -Mode Incremental `
  -TemplateParameterObject $armParameters `
  -Verbose

# NOTES
# for VM sizes see https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
# to get the list of all available locations call Get-AzureRmLocation