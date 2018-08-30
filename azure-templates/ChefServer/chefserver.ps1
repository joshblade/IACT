$reiAzureLoginCreds = get-credential -Message 'Your.Name@company.com and your company password' -UserName robert.burke@reisystems.com
Login-AzureRmAccount -Credential $reiAzureLoginCreds
##########################
Get-AzureRmVMImageOffer -Location eastus -PublisherName 'Canonical'
Get-AzureRmVMImageSku -Location 'eastus' -PublisherName 'Canonical' -Offer 'UbuntuServer'
$location = 'eastus'
$rgcheftest = New-AzureRmResourceGroup -Name 'rgcheftest' -Location $location
$rgcheftestname = $rgcheftest.ResourceGroupName
$chefStorage = New-AzureRmStorageAccount -ResourceGroupName rgcheftest -Name rbchefstorage -Location $location -Kind Storage -SkuName Standard_LRS
$chefstorageinfo = Get-AzureRmStorageAccount -ResourceGroupName $rgcheftestname -Name rbchefstorage 
$chefStorageName = $chefStorageinfo.StorageAccountName

##########################
#region Local Admin Details
$user = "devopsadmin"
$password = 'Password123$'
#2016 requires 12 chars: XXXXXXXXXXXX
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword)
#endregion

#Ubuntu Server Details
$server = 'chefrb'
$vmsize = 'Standard_D1_v2'
$PublisherName = "Canonical"
$Offer = "UbuntuServer"
$Skus = "17.04"
$Version = 'latest'
$chefVnetName = 'cheftestvnet'
#$chefNic = New-AzureRmNetworkInterface -Name 'niccheftest' -ResourceGroupName $rgcheftestname -Location $location 
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name chefSubnet -AddressPrefix 192.168.1.0/24 
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName rgcheftest -Location $location -Name $chefVnetName -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
$pip = New-AzureRmPublicIpAddress -Name ('vip-' + $server) -ResourceGroupName rgcheftest -Location $location -AllocationMethod Dynamic -DomainNameLabel $server.ToLower()
# Create a public IP address and specify a DNS name
$chefnic = New-AzureRmNetworkInterface -Force -Name ('nic-' + $server) -ResourceGroupName $rgcheftest.ResourceGroupName -Location $location -SubnetId $vnet.Subnets.id -PublicIpAddressId $pip.Id
$osDiskVhdUri1 = "https://$chefStorageName.blob.core.windows.net/vhds/"+$server+"_os.vhd"
#curl -L https://www.opscode.com/chef/install.sh | sudo bash
#curl -L http://rbchefstorage.blob.core.windows.net/scripts/setup.sh?sv=2017-04-17&ss=bfqt&srt=sco&sp=rwdlacup&se=2017-09-19T00:29:10Z&st=2017-09-18T16:29:10Z&spr=https,http&sig=SjI8jMi8uinwDlVKjN39FD4nJs0dpHjgTXVJlJ7KjAY%3D | sudo bash

#Build VM
$chefVmConfig = New-AzureRmVMConfig -VMName $server -VMSize $vmsize | `
Set-AzureRmVMOperatingSystem -ComputerName $server -Linux  -Credential $cred| `
Set-AzureRmVMSourceImage -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version latest | `
Set-AzureRmVMOSDisk -VhdUri $osDiskVhdUri1 -name ($server+'_osDisk') -CreateOption FromImage -Caching ReadWrite | `
Add-AzureRmVMNetworkInterface -Id $chefnic.Id

New-AzureRmVM -ResourceGroupName $rgcheftestname -Location $location -VM $chefvmconfig -Verbose
set-azurermvmcustomscriptextension -VMName $server -ResourceGroupName $rgcheftestname -Location $location -StorageAccountName $chefStorageName -FileName setup.sh -ContainerName scripts -Name chefinstall -Run setup.sh -StorageAccountKey '7KWDGyCTu4cCaOhLLuJbadHGHEu95m4b3zVmwfHmiF4IDyDi5F0Fpbymkl46LRCgyxjbw2I1fQwd4Mo8TN34AA=='
Update-AzureRmVM -Id 

 





