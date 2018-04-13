param(
   [string] [Parameter(Mandatory = $true)] $Name
)

. "$PSScriptRoot\..\Common.ps1"

$ResourceGroupName = "PS-M2-$Name"
$Location = "West Europe"
$KeyVaultName = "$Name-psm2vault"

CheckLoggedIn

EnsureResourceGroup $ResourceGroupName $Location

$keyVault = EnsureKeyVault $KeyVaultName $ResourceGroupName $Location

$certThumbprint, $certPassword, $certPath = CreateSelfSignedCertificate $Name

$kvCert = ImportCertificateIntoKeyVault $KeyVaultName $Name $certPath $certPassword

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



