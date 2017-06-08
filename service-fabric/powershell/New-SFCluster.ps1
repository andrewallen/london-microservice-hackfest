<#
 .SYNOPSIS
    Deploys a Service Fabric Cluster to Azure.

 .DESCRIPTION
    Deploys a Service Fabric Cluster to Azure.

 .PARAMETER subscriptionId
	The subscription id where the template will be deployed.

 .PARAMETER region
	Optional, the region where the SF cluster will be deployed.

 .PARAMETER sfClusterName
	The globally unique name of the SF cluster.

 .PARAMETER sfClusterSize
	Optional, the number of nodes in the SF cluster. 1 or 3 nodes is considered non-production / development purposes only, while 5 or greater is supported for production.

 .PARAMETER sfResourceGroupName
	Optional, the resource group where the SF cluster will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER vmSku
	Optional, the VM SKU / instance type to be deployed in the VM scale set.

 .PARAMETER vmOs
	Optional, the OS type deployed onto the VM scale set VMs.

 .PARAMETER vmUserName
	Optional, the local username for the VMs in the VM scale set.

 .PARAMETER vmPassword
	Optional, the local password 

 .PARAMETER keyVaultName
	Optional, the name of the Key Vault.

 .PARAMETER keyVaultResourceGroupName
	Optional, the resource group where the Key Vault will be deployed.

 .PARAMETER certificateOutputFolder
	Optional, the location where the SF cluster certificate stored in Key Vault is retained locally.

 .PARAMETER certificatePassword
	Optional, the password on the certificate file.

 .PARAMETER certificateSubjectName
	Optional, the certificate distinguished name for use on the SF cluster.
#>

param (
	[Parameter(Mandatory=$True)]
	[string]
	$subscriptionId = "69a92802-8060-4273-9c23-95547f994da1",

	[string]
	$region = "westeurope",

	[Parameter(Mandatory=$True)]
	[string]
	$sfClusterName = "hackfest-sf-c1",

	[string]
	$sfClusterSize = 5,
	
	[string]
	$sfResourceGroupName = "$SfClusterName-$Region-rg",

	[string]
	$vmSku = "Standard_A2_v2",

	[string]
	$vmOs = "WindowsServer2016DatacenterwithContainers",

	[string]
	$vmUserName = "localAdmin",

	[string]
	$vmPassword = "Password1234!",

	[Parameter(Mandatory=$True)]
	[string]
	$keyVaultName = "hackfest-kv-$region",

	[string]
	$keyVaultResouceGroupName = "$keyVaultName-rg",

	[string]
	$certificateOutputFolder = "C:\Certs",

	[string]
	$certificatePassword = "Password1234!",

	[string]
	$certificateSubjectName = "$sfResourceGroupName.$region.cloudapp.azure.com"
)

# Hash secrets

$vmPasswordHash = $vmPassword | ConvertTo-SecureString -AsPlainText -Force;
$certificatePasswordHash = $certificatePassword | ConvertTo-SecureString -AsPlainText -Force;

# Check $CertificateOutputFolder folder exists and create if required

Write-Host "* Checking if $certificateOutputFolder exists...";
If(!(test-path $certificateOutputFolder))
{
	Write-Host "... creating $certificateOutputFolder";
	New-Item -ItemType Directory -Force -Path $certificateOutputFolder;
}

# Authenticate and select appropriate subscription:

Write-Host "* Logging in...";
Login-AzureRmAccount;
Write-Host "* Switching subscription to $subscriptionId...";
Select-AzureRmSubscription -SubscriptionId $subscriptionId;

# Create Key Vault in its own Resource Group (if required):

Write-Host "* Checking Key Vault $keyVaultName in resource group $keyVaultResouceGroupName..."
Get-AzureRmResourceGroup -Name $keyVaultResouceGroupName -ev notPresent -ea 0
if ($notPresent)
{
    Write-Host "... creating resource group $keyVaultResouceGroupName";
	New-AzureRmResourceGroup -Name $keyVaultResouceGroupName -Location $region;
};
New-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $keyVaultResouceGroupName -Location $region -EnabledForDeployment;

# Create SF cluster on Azure (depends on existing Key Vault, not in the same Resource Group - i.e. best practice):

Write-Host "* Creating a $sfClusterSize-node Service Fabric Cluster $sfClusterName in resource group $sfResourceGroupName..."
New-AzureRmServiceFabricCluster -ResourceGroupName $sfResourceGroupName -CertificateOutputFolder $certificateOutputFolder `
-CertificatePassword $certificatePasswordHash -CertificateSubjectName $certificateSubjectName -ClusterSize $sfClusterSize `
-KeyVaultName $keyVaultName -KeyVaultResouceGroupName $keyVaultResouceGroupName -Location $region -Name $sfClusterName `
-OS $vmOs -VmPassword $vmPasswordHash -VmSku $vmSku -VmUserName $vmUserName

# Import certificate into browser to be able to authenticate to SF Explorer - required to access SfExplorer

#Import-PfxCertificate -FilePath $CertificateOutputFolder\$SfClusterName*.pfx -Password CertificatePassword -CertStoreLocation Cert:\CurrentUser\My -Exportable

# To clean up - also remember to remove the browser certificate

#Remove-AzureRmResourceGroup -Name $SfResourceGroupName -Force # removes all SF resources, but Key Vault is assumed to be retained