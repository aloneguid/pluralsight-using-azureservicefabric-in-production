$ErrorActionPreference = 'Stop'

$t = [Reflection.Assembly]::LoadWithPartialName("System.Web")
Write-Host "Loaded $($t.FullName)."

function CheckLoggedIn()
{
    $rmContext = Get-AzureRmContext

    if($rmContext.Account -eq $null) {
        Write-Host "You are not logged into Azure. Use Login-AzureRmAccount to log in first and optionally select a subscription" -ForegroundColor Red
        exit
    }

    Write-Host "You are running as '$($rmContext.Account.Id)' in subscription '$($rmContext.Subscription.Name)'"
}

function EnsureResourceGroup([string]$Name, [string]$Location)
{
    # Prepare resource group
    Write-Host "Checking if resource group '$Name' exists..."
    $resourceGroup = Get-AzureRmResourceGroup -Name $Name -Location $Location -ErrorAction Ignore
    if($resourceGroup -eq $null)
    {
        Write-Host "  resource group doesn't exist, creating a new one..."
        $resourceGroup = New-AzureRmResourceGroup -Name $Name -Location $Location
        Write-Host "  resource group created."
    }
    else
    {
        Write-Host "  resource group already exists."
    }
}

function EnsureKeyVault([string]$Name, [string]$ResourceGroupName, [string]$Location)
{
    # properly create a new Key Vault
    # KV must be enabled for deployment (last parameter)
    Write-Host "Checking if Key Vault '$Name' exists..."
    $keyVault = Get-AzureRmKeyVault -VaultName $Name -ErrorAction Ignore
    if($keyVault -eq $null)
    {
        Write-Host "  key vault doesn't exist, creating a new one..."
        $keyVault = New-AzureRmKeyVault -VaultName $Name -ResourceGroupName $ResourceGroupName -Location $Location -EnabledForDeployment
        Write-Host "  Key Vault Created and enabled for deployment."
    }
    else
    {
        Write-Host "  key vault already exists."
    }

    $keyVault
}

function CreateSelfSignedCertificate([string]$DnsName, [switch]$AsString = $false)
{
    Write-Host "Creating self-signed certificate with dns name $DnsName"
    
    $filePath = "$PSScriptRoot\$DnsName.pfx"

    Write-Host "  generating password... " -NoNewline
    $certPassword = GeneratePassword
    Write-Host "$certPassword"

    Write-Host "  generating certificate... " -NoNewline
    $securePassword = ConvertTo-SecureString $certPassword -AsPlainText -Force
    $thumbprint = (New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation Cert:\CurrentUser\My -KeySpec KeyExchange).Thumbprint
    Write-Host "$thumbprint."
    
    Write-Host "  exporting to $filePath..."
    $certContent = (Get-ChildItem -Path cert:\CurrentUser\My\$thumbprint)
    $t = Export-PfxCertificate -Cert $certContent -FilePath $filePath -Password $securePassword
    Write-Host "  exported."

    $thumbprint

    if($AsString.IsPresent)
    {
        $secret = GetCertificateAsString $filePath $certPassword
        $secret
    }
    else
    {
        $certPassword
        $filePath
    }
}

function ImportCertificateIntoKeyVault([string]$KeyVaultName, [string]$CertName, [string]$CertFilePath, [string]$CertPassword)
{
    Write-Host "Importing certificate..."
    Write-Host "  generating secure password..."
    $securePassword = ConvertTo-SecureString $CertPassword -AsPlainText -Force
    Write-Host "  uploading to KeyVault..."
    Import-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -FilePath $CertFilePath -Password $securePassword
    Write-Host "  imported."
}

function GeneratePassword()
{
    [System.Web.Security.Membership]::GeneratePassword(15,2)
}

function GetCertificateAsString([string]$CertFilePath, [string]$CertPassword)
{
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
    $collection.Import($CertFilePath, $CertPassword, $flag)
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
    $clearBytes = $collection.Export($pkcs12ContentType)
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
    $fileContentEncoded
}

function ImportStringCertificateIntoKeyVault([string]$KeyVaultName, [string]$CertName, [string]$CertString)
{
    #$secret = ConvertTo-SecureString -String $CertString -AsPlainText –Force
    #$secretContentType = "application/x-pkcs12"
    #Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $CertName -SecretValue $secret -ContentType $secretContentType
}

function ReadConfig($Name)
{
    $path = "$PSScriptRoot\$Name"

    if(Test-Path $path)
    {
        [pscustomobject](Get-Content $path -Raw | ConvertFrom-StringData)
    }
    else
    {
        @{}
    }
}

function WriteConfig($Name, $Config)
{
    $path = "$PSScriptRoot\$Name"

    Convertto
}