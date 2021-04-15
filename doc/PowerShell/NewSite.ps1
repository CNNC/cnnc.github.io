Import-Module .AESKey.ps1
Import-Module .IIS.ps1
Import-Module .sql.ps1
Import-Module .AddDistrict.ps1
Import-Module .'D:\Home\cnnc.github.io\doc\PowerShell\iis\urltest.ps1'

# $Name=PPS
# RestoreSQL  $Name
# DistrictKey $Name
# AddDistrict $Name
# IISSite $Name
urltest -url 'https://asd.schoolstreamk12.com'