Import-Module .AESKey.ps1
Import-Module .IIS.ps1
Import-Module .sql.ps1
Import-Module .AddDistrict.ps1

$Name="PSTTTI"
$SchoolName="PSTTTI school"

RestoreSQL
DistrictKey
AddDistrict
IISSite