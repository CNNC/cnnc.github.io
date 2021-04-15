function AddDistrict($Name,$SchoolName)
{
    # Add link to SQLDB District-Config

    $Welcome = "Welcome to "
    $https = "https://"
    $httpss = "/"
    $oo = "'"

    $DNS = ".schoolstreamk12.com"
    $Hoster = $Name + $DNS

    $INSERT1 = " INSERT INTO [dbo].[District] ([DistrictName],[Abbr],[StateID],[TimeZoneID],[DBConectionString],[Description],[RowGuid],[Enrollment],[URL],[IsVirtualDistrict],[IsPublicCN],[isAllowBindGlobal],[MixVer],[ForwardTo],[OldDistrictID]) VALUES ("
    $Do = ","
    $NUM1 = ",1,0,"
    $RowGuid = ",'10685903-109B-435C-9E13-85C6763251E4','0',"
    $cloud = ",0,0,1,0,'https://cloud.schoolstreamk12.com','NULL')"

    $INSERT = $INSERT1 + $oo + $SchoolName + $oo + $Do + $oo + $Name + $oo + $NUM1 + $oo + $encryptedString + $oo + $Do + $oo + $Welcome + $SchoolName + $oo + $RowGuid + $oo + $https + $Hoster + $httpss + $oo + $cloud


    $Database = 'District_Configuration'
    $Server = '"192.168.4.62,1433"'
    $UserName = 'sa'
    $Password = '2018p@ssw0rd'

    $SqlConn = New-Object System.Data.SqlClient.SqlConnection

    $SqlConn.ConnectionString = "Data Source=$Server;user id=$UserName;pwd=$Password;Initial Catalog=$Database "
    $SqlConn.open()

    $cmd = New-Object System.Data.SqlClient.SqlCommand

    $cmd.connection = $SqlConn

    #$cmd.commandtext = "create database psDB"
    #$cmd.commandtext = "backup database Test to disk='D:/Test.bak'"

    $cmd.commandtext = $INSERT

    $cmd.ExecuteScalar()

}