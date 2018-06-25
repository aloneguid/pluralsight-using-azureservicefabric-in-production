param(
   [string] [Parameter(Mandatory = $true)] $ClusterName,
   [string] $Location = "westeurope"
)

. "$PSScriptRoot\Common.ps1"

$typeName = "Pluralsight.SfProdType"
$path = "$PSScriptRoot\TestAppPkg"
$endpoint = "$ClusterName.$Location.cloudapp.azure.com:19000"
$thumbprint = Get-Content "$PSScriptRoot\$ClusterName.thumb.txt"

Write-Host "connecting to cluster $endpoint using cert thumbprint $thumbprint..."
Connect-ServiceFabricCluster -ConnectionEndpoint $endpoint `
    -X509Credential `
    -ServerCertThumbprint $thumbprint `
    -FindType FindByThumbprint -FindValue $thumbprint `
    -StoreLocation CurrentUser -StoreName My

Write-Host "Unregistering $typeName if present..."
Unregister-ApplicationTypeCompletely $typeName

Write-Host "uploading test application binary to the cluster..."
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $path -ApplicationPackagePathInImageStore $typeName -TimeoutSec 1800 -ShowProgress

Write-Host "registering application..."
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $typeName

Write-Host "creating application..."
New-ServiceFabricApplication -ApplicationName "fabric:/$typeName" -ApplicationTypeName $typeName -ApplicationTypeVersion "1.0.0"
