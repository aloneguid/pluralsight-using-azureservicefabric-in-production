. "$PSScriptRoot\Common.ps1"

$ResourceGroupPrefix = "ASF-"  # Resource group everything will be created in

CheckLoggedIn

Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName.StartsWith($ResourceGroupPrefix)} | % {
    #$_ | fl
    Write-Host "removing $($_.ResourceGroupName)..."
    Remove-AzureRmResourceGroup -Name $_.ResourceGroupName -Force -Verbose
}



