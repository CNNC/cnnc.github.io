function IISSite 
{
    Write-Output "Create the IIS site"
    # Add IIS site
    Import-Module WebAdministration
    $DNS = ".schoolstreamk12.com"
    $Hoster = $Name + $DNS
    $IISPath = "IIS:\Sites\"
    $IISSitePath = $IISPath + $Name
    $IISAppPool = "IIS:\AppPools\"
    $IISAppPoolPath = $IISAppPool + $Name
    $IP = "*" 
    $cert = "E4252100C72D5699AB82CA293205B3448C7938C2"
    $my = "my"
    $PhysicalPath
    Import-PfxCertificate -FilePath 'E:\schoolk12.PFX' -CertStoreLocation cert:\localmachine\MY -Password (convertTo-SecureString -String "2018p@ssw0rd" -AsPlainText -Force )
    # Get-Item cert:\localmachine\MY\E4252100C72D5699AB82CA293205B3448C7938C2 | new-item 0.0.0.0!443
    New-Website -Name $Name -IP $IP  -Port 80  -HostHeader $Hoster -PhysicalPath "E:\pst\publish\publish"
    New-Item $IISAppPoolPath
    Set-ItemProperty $IISAppPoolPath managedRuntimeVersion v4.0
    Set-ItemProperty $IISSitePath -name applicationPool -value $Name

    New-WebBinding -Name $Name -IP $IP -Port 443 -Protocol https -HostHeader $Hoster  -SslFlags 1

    (get-webbinding -Name $Name -port 443  -Protocol https).addsslcertificate($cert, $my)
    # New-WebApplication -Name ABSD -Site 'Default Web Site' -PhysicalPath C:\inetpub\wwwroot
    #Set-ItemProperty IIS:\apppools\DefaultAppPool -name "enable32BitAppOnWin64" -Value "true"
    iisreset

    $Sitelink = $https + $Hoster + $httpss
    Write-Output "Your site has been created. Login to the link:" 
    Write-Output $Sitelink
}