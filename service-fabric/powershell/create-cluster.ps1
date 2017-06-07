# Set parameters:

$subscription = "Internal Development (anallen@microsoft.com)"

$Location = "westeurope"
$Name = "hackfest-sf-5n"
$ResourceGroupName = "$Name-$Location-rg"
$ClusterSize = 1

$VmSku = "Standard_D2_V2"
$OS = "WindowsServer2016DatacenterwithContainers" # 
$VmUserName = "localAdmin"
$VmPassword = "Password1234!" | ConvertTo-SecureString -AsPlainText -Force

$KeyVaultName = "hackfest-kv-$Location" 
$KeyVaultResouceGroupName = "$KeyVaultName-rg"

$CertificateOutputFolder = "C:\Certs"
$CertificatePassword = "Password1234!" | ConvertTo-SecureString -AsPlainText -Force
$CertificateSubjectName = "$ResourceGroupName.$Location.cloudapp.azure.com"


# Authenticate and select appropriate subscription:

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName $subscription # required if your account has access to multiple subscriptions

# Create Key Vault in its own Resource Group (if required):

New-AzureRmResourceGroup -Name $KeyVaultResouceGroupName -Location $Location
New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $KeyVaultResouceGroupName -Location $Location -EnabledForDeployment

# Create SF cluster on Azure (depends on existing Key Vault, not in the same Resource Group - i.e. best practice):

New-AzureRmServiceFabricCluster -ResourceGroupName $ResourceGroupName -CertificateOutputFolder $CertificateOutputFolder -CertificatePassword $CertificatePassword -CertificateSubjectName $CertificateSubjectName -ClusterSize $ClusterSize -KeyVaultName $KeyVaultName -KeyVaultResouceGroupName $KeyVaultResouceGroupName -Location $Location -Name $Name -OS $OS -VmPassword $VmPassword -VmSku $VmSku -VmUserName $VmUserName

# Import certificate into browser to be able to authenticate to SF Explorer:

Import-PfxCertificate -FilePath $CertificateOutputFolder\$Name*.pfx -Password CertificatePassword -CertStoreLocation Cert:\CurrentUser\My -Exportable

# To clean up:

Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force

# Also remember to remove the browser certificate.
