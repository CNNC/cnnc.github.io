
function RestoreSQL($Name) 
{
    # Restore SQL
    $Server = '"192.168.4.62,2433"'
    $UserName = 'sa'
    $Password = '2018p@ssw0rd'

    $SqlConn = New-Object System.Data.SqlClient.SqlConnection
 
    $SqlConn.ConnectionString = "Data Source=$Server;user id=$UserName;pwd=$Password"
    $SqlConn.open()

    $cmd = New-Object System.Data.SqlClient.SqlCommand

    $cmd.connection = $SqlConn

    #$cmd.commandtext = "create database psDB"
    #$cmd.commandtext = "backup database Test to disk='D:/Test.bak'"
    #  RESTORE FILELISTONLY FROM DISK = 'E:\UserData\SJUSD\SJUSD_ALLS_1.bak'  -run in sql


    $re1 = "restore database "
    $re2 = " from disk='E:\UserData\SJUSD\SJUSD_ALLS_1.bak' "
    $re3 = " WITH "
    $re4 = " MOVE 'DEMO_CentralDB_Data' TO 'E:\Program Files\Microsoft SQL Server\MSSQL12.WIN462DB\MSSQL\DATA\"
    $re5 = ".mdf',"
    $re6 = " MOVE 'DEMO_CentralDB_Log' TO 'E:\Program Files\Microsoft SQL Server\MSSQL12.WIN462DB\MSSQL\DATA\"
    $re7 = "_log.ldf'"
    $re = $re1 + $Name + $re2 + $re3 + $re4 + $Name + $re5 + $re6 + $Name + $re7

    Write-Output "The database is being prepared, please wait a moment" 
    
    $ALTER1="ALTER DATABASE "
    $ALTER2=" SET SINGLE_USER with ROLLBACK IMMEDIATE"
    $al=$ALTER1+$Name+$ALTER2

    $drop="DROP DATABASE "
    $dropdata=$drop+$Name

# SINGLE_USER
    $cmd.commandtext = $al
    $cmd.ExecuteScalar() | Out-Null
# DROP DATABASE
    $cmd.commandtext = $dropdata
    $cmd.ExecuteScalar() | Out-Null
     Write-Output "The database delete" 
# Restore
    $cmd.commandtext = $re

    $cmd.ExecuteScalar() | Out-Null
    Write-Output "Success" 
}


RestoreSQL SJUSD