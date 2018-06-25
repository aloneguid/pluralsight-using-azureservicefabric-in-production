$ErrorActionPreference = 'Stop'

$t = [Reflection.Assembly]::LoadWithPartialName("System.Web")
Write-Host "Loaded $($t.FullName)."

function CheckLoggedIn()
{
    Write-Host "Validating if you are logged in..."
    $rmContext = Get-AzureRmContext

    if($rmContext.Account -eq $null) {
        Write-Host "  you are not logged into Azure. Use Login-AzureRmAccount to log in first and optionally select a subscription" -ForegroundColor Red
        exit
    }

    Write-Host "  account:      '$($rmContext.Account.Id)'"
    Write-Host "  subscription: '$($rmContext.Subscription.Name)'"
    Write-Host "  tenant:       '$($rmContext.Tenant.Id)'"
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

function CreateSelfSignedCertificate([string]$DnsName)
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
    Set-Content -Path "$PSScriptRoot\$DnsName.thumb.txt" -Value $thumbprint
    Set-Content -Path "$PSScriptRoot\$DnsName.pwd.txt" -Value $certPassword
    Write-Host "  exported."

    $thumbprint
    $certPassword
    $filePath
}

function ImportCertificateIntoKeyVault([string]$KeyVaultName, [string]$CertName, [string]$CertFilePath, [string]$CertPassword)
{
    #Write-Host

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

function EnsureSelfSignedCertificate([string]$KeyVaultName, [string]$CertName)
{
    $localPath = "$PSScriptRoot\$CertName.pfx"
    $existsLocally = Test-Path $localPath

    # create or read certificate
    if($existsLocally) {
        Write-Host "Certificate exists locally."
        $thumbprint = Get-Content "$PSScriptRoot\$Certname.thumb.txt"
        $password = Get-Content "$PSScriptRoot\$Certname.pwd.txt"
        Write-Host "  thumb: $thumbprint, pass: $password"

    } else {
        $thumbprint, $password, $localPath = CreateSelfSignedCertificate $CertName
    }

    #import into vault if needed
    Write-Host "Checking certificate in key vault..."
    $kvCert = Get-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName
    if($kvCert -eq $null) {
        Write-Host "  importing..."
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $kvCert = Import-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -FilePath $localPath -Password $securePassword
    } else {
        Write-Host "  certificate already imported."
    }

    $kvCert
}

function Connect-SecureCluster([string]$ClusterName, [string]$Thumbprint)
{
    $Endpoint = "$ClusterName.westeurope.cloudapp.azure.com:19000"

    Write-Host "connecting to cluster $Endpoint using cert thumbprint $Thumbprint..."
    
    Connect-ServiceFabricCluster -ConnectionEndpoint $Endpoint `
        -X509Credential `
        -ServerCertThumbprint $Thumbprint `
        -FindType FindByThumbprint -FindValue $Thumbprint `
        -StoreLocation CurrentUser -StoreName My
}

function Unregister-ApplicationTypeCompletely([string]$ApplicationTypeName)
{
    Write-Host "checking if application type $ApplicationTypeName is present.."
    $type = Get-ServiceFabricApplicationType -ApplicationTypeName $ApplicationTypeName
    if($type -eq $null) {
        Write-Host "  application is not in the cluster"
    } else {
        $runningApps = Get-ServiceFabricApplication -ApplicationTypeName $ApplicationTypeName
        foreach($app in $runningApps) {
            $uri = $app.ApplicationName.AbsoluteUri
            Write-Host "    unregistering '$uri'..."

            $t = Remove-ServiceFabricApplication -ApplicationName $uri -ForceRemove -Verbose -Force
        }

        Write-Host "  unregistering type..."
        $t =Unregister-ServiceFabricApplicationType `
            -ApplicationTypeName $ApplicationTypeName -ApplicationTypeVersion $type.ApplicationTypeVersion `
            -Force -Confirm

    }
}