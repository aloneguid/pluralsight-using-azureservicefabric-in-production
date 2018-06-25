<#
  You should have already created Service Fabric cluster before running this script.
  The script generates key and cert from your cluster pfx certificate in order for Traefik to use it.
  It uploads Traefik web application to the remote cluster with generated keys and starts it.
#>

param(
   [string] [Parameter(Mandatory = $true)] $ClusterName,
   [string] $Location = "westeurope"
)

. "$PSScriptRoot\Common.ps1"

$certPath = "$PSScriptRoot\$ClusterName.pfx"
$pass = Get-Content "$PSScriptRoot\$ClusterName.pwd.txt"
$keyPath = "$PSScriptRoot\Traefik\TraefikPkg\code\certs\servicefabric.key"
$crtPath = "$PSScriptRoot\Traefik\TraefikPkg\code\certs\servicefabric.crt"
$thumbprint = Get-Content "$PSScriptRoot\$ClusterName.thumb.txt"
$typeName = "TraefikType"
$path = "$PSScriptRoot\Traefik"
$endpoint = "$ClusterName.$Location.cloudapp.azure.com:19000"

# key management
Write-Host "input"
Write-Host "  cert: $certPath"
Write-Host "  pass: $pass"
Write-Host "  key: $keyPath"
openssl pkcs12 -in $certPath -nocerts -nodes -out $keyPath -passin pass:$pass
openssl pkcs12 -in $certPath -clcerts -nokeys -out $crtPath -passin pass:$pass
Write-Host "generated .key to $keyPath and .crt to $crtPath"

Write-Host "connecting to cluster $endpoint using cert thumbprint $thumbprint..."
Connect-ServiceFabricCluster -ConnectionEndpoint $Endpoint `
    -X509Credential `
    -ServerCertThumbprint $thumbprint `
    -FindType FindByThumbprint -FindValue $thumbprint `
    -StoreLocation CurrentUser -StoreName My

Unregister-ApplicationTypeCompletely $typeName

# application management
Write-Host "uploading Traefik binary to the cluster..."
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $Path -ApplicationPackagePathInImageStore $TypeName -TimeoutSec 1800 -ShowProgress

Write-Host "registering application..."
Register-ServiceFabricApplicationType -ApplicationPathInImageStore $TypeName

Write-Host "creating application..."
New-ServiceFabricApplication -ApplicationName "fabric:/$TypeName" -ApplicationTypeName $TypeName -ApplicationTypeVersion "1.0.0"
