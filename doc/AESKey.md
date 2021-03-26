```PowerShell
# Create key to SQL District-Config
# Dim Config with DistrictConfig

$Name=out
$DBConectionString1="Data Source=192.168.4.62,2433;Initial Catalog="
$DBConectionString3=";User ID=sa;Password=2018p@ssw0rd;MultiSubnetFailover=True;Persist Security Info=True;MultipleActiveResultSets=True;"
$DBConectionString = $DBConectionString1+$Name+$DBConectionString3
$DBConectionStringb = [Text.Encoding]::UTF8.GetBytes($DBConectionString)
# sn.key
$rest = "opKs)47WRgeknE@9@lewAV=Rqxp^io6RPW4rYgy4@xyBMqG!"
# String to byte

# Create the key of New School
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
```
