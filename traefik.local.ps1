<#
  This script deploys Traefik to local development cluster.
#>

. "$PSScriptRoot\Common.ps1"

$typeName = "TraefikType"
$path = "$PSScriptRoot\TraefikLocal"

Write-Host "connecting to local cluster..."
Connect-ServiceFabricCluster

Unregister-ApplicationTypeCompletely $typeName

# application management
Write-Host "uploading Traefik binary to the cluster..."
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $Path -ApplicationPackagePathInImageStore $TypeName -TimeoutSec 1800 -ShowProgress

Write-Host "registering application..."
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $TypeName

Write-Host "creating application..."
New-ServiceFabricApplication -ApplicationName "fabric:/$TypeName" -ApplicationTypeName $TypeName -ApplicationTypeVersion "1.0.0"
