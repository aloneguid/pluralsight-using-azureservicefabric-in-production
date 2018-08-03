param(
   [string] [Parameter(Mandatory = $true)] $Name
)

$ResourceGroupName = "ASF-$Name"  # Resource group everything will be created in
$Location = "West Europe"         # Physical location of all the resources

. "$PSScriptRoot\..\Common.ps1"

CheckLoggedIn

Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Compute/VirtualMachineScaleSets

#Get-AzureRmVmss -ResourceGroupName $ResourceGroupName -VMScaleSetName <Virtual Machine scale set name>