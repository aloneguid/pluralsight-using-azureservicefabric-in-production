. "$PSScriptRoot\..\Common.ps1"

# Check that you're logged in to Azure before running anything at all, the call will
# exit the script if you're not
CheckLoggedIn

$config = ReadConfig "m3.ini"

Write-Host $config.CertThumbprint
Write-Host $config.CertValue

# For development purposes, we create a self-signed cluster certificate here. 
$certThumbprint, $certString = CreateSelfSignedCertificate -DnsName "octometa" -AsString

Write-Host "thumb: $certThumbprint"
Write-Host "content: $certString"

