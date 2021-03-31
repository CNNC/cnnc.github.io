Connect-AzAccount

# If you don't know which location you want to use, you can list the available locations. 
# Get-AzLocation | select Location
$location = "eastus"

# Create a resource group
$resourceGroup = "myResourceGroup"
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create a storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name "mystorageaccount" `
  -SkuName Standard_LRS `
  -Location $location `

$ctx = $storageAccount.Context

# Create a container
$containerName = "quickstartblobs"
New-AzStorageContainer -Name $containerName -Context $ctx -Permission blob

# Upload blobs to the container

# upload a file to the default account (inferred) access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image000.jpg" `
  -Container $containerName `
  -Blob "Image001.jpg" `
  -Context $ctx 

# upload a file to the Hot access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image001.jpg" `
  -Container $containerName `
  -Blob "Image001.jpg" `
  -Context $ctx 
  -StandardBlobTier Hot

# upload another file to the Cool access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image002.png" `
  -Container $containerName `
  -Blob "Image002.png" `
  -Context $ctx
  -StandardBlobTier Cool

# upload a file to a folder to the Archive access tier
Set-AzStorageBlobContent -File "D:\_TestImages\foldername\Image003.jpg" `
  -Container $containerName `
  -Blob "Foldername/Image003.jpg" `
  -Context $ctx 
  -StandardBlobTier Archive



  # List the blobs in a container
  Get-AzStorageBlob -Container $ContainerName -Context $ctx | select Name



  # Download blobs
 # download first blob
Get-AzStorageBlobContent -Blob "Image001.jpg" `
-Container $containerName `
-Destination "D:\_TestImages\Downloads\" `
-Context $ctx 

# download another blob
Get-AzStorageBlobContent -Blob "Image002.png" `
-Container $containerName `
-Destination "D:\_TestImages\Downloads\" `
-Context $ctx

# Data transfer with AzCopy
azcopy login
azcopy copy 'C:\myDirectory\myTextFile.txt' 'https://mystorageaccount.blob.core.windows.net/mycontainer/myTextFile.txt'





# login to azure and add mp4 to video

Connect-AzAccount

$resourceGroup='TrainingVideo'
$storageAccount=Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name 'rrvideo'
$ctx=$storageAccount.Context
#Expense Report
$ER= 'asset-4fd5g5d8f-56g4c2-x651f8sc1v-vsv8fd8ds1-1v68z6v1r161s'

$con= Get-AzStorageContainer -Context $ctx -Name $ER


# upload a file to the default account (inferred) access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image000.jpg" `
  -Container $con `
  -Blob "Image001.jpg" `
  -Context $ctx 

# upload a file to the Hot access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image001.jpg" `
  -Container $con `
  -Blob "Image001.jpg" `
  -Context $ctx 
  -StandardBlobTier Hot

# upload another file to the Cool access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image002.png" `
  -Container $con `
  -Blob "Image002.png" `
  -Context $ctx
  -StandardBlobTier Cool

# upload a file to a folder to the Archive access tier
Set-AzStorageBlobContent -File "D:\_TestImages\foldername\Image003.jpg" `
  -Container $con `
  -Blob "Foldername/Image003.jpg" `
  -Context $ctx 
  -StandardBlobTier Archive


# 上传一个文件夹下的所有文件到azure blob
  Get-ChildItem -Path "D:\ConsoleApplication1" -File -Recurse | Set-azStorageBlobContent -Container $Con -Context $ctx

# 强制上传文件,替换文件
Set-AzStorageBlobContent -File "D:\_TestImages\Image000.jpg" -Container $con  -Blob "Image001.jpg"  -Context $ctx -Force

# upload a file to the Hot access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image001.jpg"  -Container $con  -Blob "Image001.jpg"  -Context $ctx  -StandardBlobTier Hot -Force

# upload another file to the Cool access tier
Set-AzStorageBlobContent -File "D:\_TestImages\Image002.png"  -Container $con -Blob "Image002.png"   -Context $ctx -StandardBlobTier Cool -Force


