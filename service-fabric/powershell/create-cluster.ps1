#
# create-cluster.ps1
#

# Parameters:

$Subscription = "Internal Development (anallen@microsoft.com)"
$Region = "westeurope"

$SfClusterName = "hackfest-sf-c1"
$SfClusterSize = 5 # 1 & 3 node clusters considered non-production; production >= 5
$SfResourceGroupName = "$SfClusterName-$Region-rg"

$VmSku = "Standard_A2_v2" # Standard_A2_v2, Standard_D2_V2
$VmOs = "WindowsServer2016DatacenterwithContainers" # UbuntuServer1604, WindowsServer2016DatacenterwithContainers
$VmUserName = "localAdmin"
$VmPassword = "Password1234!" | ConvertTo-SecureString -AsPlainText -Force

$KeyVaultName = "hackfest-kv-$Region" # Key Vault has to be in the same region as the SF cluster
$KeyVaultResouceGroupName = "$KeyVaultName-rg" # Key Vault should be in seperate RG from SF cluster

$CertificateOutputFolder = "C:\Certs"
$CertificatePassword = "Password1234!" | ConvertTo-SecureString -AsPlainText -Force
$CertificateSubjectName = "$SfResourceGroupName.$Region.cloudapp.azure.com"

# Check $CertificateOutputFolder folder exists and create if required

If(!(test-path $CertificateOutputFolder))
{
	New-Item -ItemType Directory -Force -Path $path
}

# Authenticate and select appropriate subscription:

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName $Subscription # required if your account has access to multiple subscriptions

# Create Key Vault in its own Resource Group (if required):

New-AzureRmResourceGroup -Name $KeyVaultResouceGroupName -Location $Region
New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $KeyVaultResouceGroupName -Location $Region -EnabledForDeployment

# Create SF cluster on Azure (depends on existing Key Vault, not in the same Resource Group - i.e. best practice):

New-AzureRmServiceFabricCluster -ResourceGroupName $SfResourceGroupName -CertificateOutputFolder $CertificateOutputFolder `
-CertificatePassword $CertificatePassword -CertificateSubjectName $CertificateSubjectName -ClusterSize $SfClusterSize `
-KeyVaultName $KeyVaultName -KeyVaultResouceGroupName $KeyVaultResouceGroupName -Location $Region -Name $SfClusterName `
-OS $VmOs -VmPassword $VmPassword -VmSku $VmSku -VmUserName $VmUserName

# Import certificate into browser to be able to authenticate to SF Explorer - required to access SfExplorer

Import-PfxCertificate -FilePath $CertificateOutputFolder\$SfClusterName*.pfx -Password CertificatePassword -CertStoreLocation Cert:\CurrentUser\My -Exportable

# To clean up:

# Remove-AzureRmResourceGroup -Name $SfResourceGroupName -Force # removes all SF resources, but Key Vault is assumed to be retained

# Also remember to remove the browser certificate.
