Import-Module .AESKey.ps1
Import-Module .IIS.ps1
Import-Module .sql.ps1
Import-Module .AddDistrict.ps1

$Name=PPS
RestoreSQL  $Name
DistrictKey $Name
AddDistrict $Name
IISSite $Name