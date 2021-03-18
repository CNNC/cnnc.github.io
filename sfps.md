`$Name="PSTTTI"
$SchoolName="PSTTTI school"






# Restore SQL
$Server     = '"192.168.4.62,2433"'
$UserName   = 'sa'
$Password   = '2018p@ssw0rd'

$SqlConn = New-Object System.Data.SqlClient.SqlConnection

$SqlConn.ConnectionString = "Data Source=$Server;user id=$UserName;pwd=$Password"
$SqlConn.open()

$cmd = New-Object System.Data.SqlClient.SqlCommand

$cmd.connection = $SqlConn

#$cmd.commandtext = "create database psDB"
#$cmd.commandtext = "backup database Test to disk='D:/Test.bak'"
#  RESTORE FILELISTONLY FROM DISK = '\\PRODNLB1N2\NAUserData462\SJUSD_0316.bak'  -run in sql


$re1="restore database "
$re2=" from disk='\\PRODNLB1N2\NAUserData462\SJUSD_0316.bak' "
$re3=" WITH "
$re4=" MOVE 'DEMO_CentralDB_Data' TO 'E:\Program Files\Microsoft SQL Server\MSSQL12.WIN462DB\MSSQL\DATA\"
$re5=".mdf',"
$re6=" MOVE 'DEMO_CentralDB_Log' TO 'E:\Program Files\Microsoft SQL Server\MSSQL12.WIN462DB\MSSQL\DATA\"
$re7="_log.ldf'"
$re=$re1+$Name+$re2+$re3+$re4+$Name+$re5+$re6+$Name+$re7

Write-Output "The database is being prepared, please wait a moment" 

$cmd.commandtext = $re


$cmd.ExecuteScalar() | Out-Null









# Create key to SQL District-Config

$DBConectionString1="Data Source=192.168.4.62,2433;Initial Catalog="
$DBConectionString3=";User ID=sa;Password=2018p@ssw0rd;MultiSubnetFailover=True;Persist Security Info=True;MultipleActiveResultSets=True;"
$DBConectionString = $DBConectionString1+$Name+$DBConectionString3
$DBConectionStringb = [Text.Encoding]::UTF8.GetBytes($DBConectionString)
# sn.key
$rest = "opKs)47WRgeknE@9@lewAV=Rqxp^io6RPW4rYgy4@xyBMqG!"
# String to byte
$encoder = new-object System.Text.UTF8Encoding
$key =  $encoder.Getbytes($rest.Substring(0,32));
$iv =  $encoder.Getbytes($rest.Substring(32));
$cipher = [Security.Cryptography.SymmetricAlgorithm]::Create('AesManaged')
# $cipher.Key=$key
# $cipher.IV=$iv
# cipher.Padding="Zeros"
$encryptor = $cipher.CreateEncryptor($key, $iv)

$memoryStream = New-Object -TypeName IO.MemoryStream
$cryptoStream = New-Object -TypeName Security.Cryptography.CryptoStream ` -ArgumentList @( $memoryStream, $encryptor, 'Write' )

$cryptoStream.Write($DBConectionStringb, 0, $DBConectionStringb.Length)
$cryptoStream.FlushFinalBlock()
$encryptedBytes = $memoryStream.ToArray()

# Base64 Encode the encrypted bytes to get a string
$encryptedString = [Convert]::ToBase64String($encryptedBytes)


Write-Output $encryptedString

Write-Output "Add a database connection string"


# Add link to SQLDB District-Config

$Welcome="Welcome to "
$https="https://"
$httpss="/"
$oo="'"

$DNS=".schoolstreamk12.com"
$Hoster =$Name+$DNS

$INSERT1=" INSERT INTO [dbo].[District] ([DistrictName],[Abbr],[StateID],[TimeZoneID],[DBConectionString],[Description],[RowGuid],[Enrollment],[URL],[IsVirtualDistrict],[IsPublicCN],[isAllowBindGlobal],[MixVer],[ForwardTo],[OldDistrictID]) VALUES ("
$Do=","
$NUM1=",1,0,"
$RowGuid=",'10685903-109B-435C-9E13-85C6763251E4','0',"
$cloud=",0,0,1,0,'https://cloud.schoolstreamk12.com','NULL')"

$INSERT=$INSERT1+$oo+$SchoolName+$oo+$Do+$oo+$Name+$oo+$NUM1+$oo+$encryptedString+$oo+$Do+$oo+$Welcome+$SchoolName+$oo+$RowGuid+$oo+$https+$Hoster+$httpss+$oo+$cloud


$Database  = 'District_Configuration'
$Server     = '"192.168.4.62,1433"'
$UserName   = 'sa'
$Password   = '2018p@ssw0rd'

$SqlConn = New-Object System.Data.SqlClient.SqlConnection

$SqlConn.ConnectionString = "Data Source=$Server;user id=$UserName;pwd=$Password;Initial Catalog=$Database "
$SqlConn.open()

$cmd = New-Object System.Data.SqlClient.SqlCommand

$cmd.connection = $SqlConn

#$cmd.commandtext = "create database psDB"
#$cmd.commandtext = "backup database Test to disk='D:/Test.bak'"

$cmd.commandtext =$INSERT

$cmd.ExecuteScalar()













Write-Output "Create the IIS site"


# Add IIS site
Import-Module WebAdministration
$DNS=".schoolstreamk12.com"
$Hoster =$Name+$DNS
$IISPath="IIS:\Sites\"
$IISSitePath=$IISPath+$Name
$IISAppPool="IIS:\AppPools\"
$IISAppPoolPath=$IISAppPool+$Name
$IP="*" 
$cert = "E4252100C72D5699AB82CA293205B3448C7938C2"
$my="my"
$PhysicalPath
Import-PfxCertificate -FilePath 'E:\schoolk12.PFX' -CertStoreLocation cert:\localmachine\MY -Password (convertTo-SecureString -String "2018p@ssw0rd" -AsPlainText -Force )
# Get-Item cert:\localmachine\MY\E4252100C72D5699AB82CA293205B3448C7938C2 | new-item 0.0.0.0!443
New-Website -Name $Name -IP $IP  -Port 80  -HostHeader $Hoster -PhysicalPath "E:\pst\publish\publish"
New-Item $IISAppPoolPath
Set-ItemProperty $IISAppPoolPath managedRuntimeVersion v4.0
Set-ItemProperty $IISSitePath -name applicationPool -value $Name

New-WebBinding -Name $Name -IP $IP -Port 443 -Protocol https -HostHeader $Hoster  -SslFlags 1

(get-webbinding -Name $Name -port 443  -Protocol https).addsslcertificate($cert,$my)
# New-WebApplication -Name ABSD -Site 'Default Web Site' -PhysicalPath C:\inetpub\wwwroot
#Set-ItemProperty IIS:\apppools\DefaultAppPool -name "enable32BitAppOnWin64" -Value "true"
iisreset


$Sitelink=$https+$Hoster+$httpss

Write-Output "Your site has been created. Login to the link:" 

Write-Output $Sitelink`