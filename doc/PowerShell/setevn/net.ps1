# Install .net3.5
Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3"

# Install .net4.7.2
<#
     
    .SYNOPSIS
        Installs .Net 4.7.2
     
    .DESCRIPTION
        See .SYNOPSIS
 
    .PARAMETER DownloadDirectory
        This parameter is OPTIONAL.
 
        This parameter takes a string that represents the full path to the directory that will contain the installation .exe download.
 
    .PARAMETER Restart
        This parameter is OPTIONAL.
 
        This parameter is a switch. If uses, the localhost will restart after .Net 4.7.2 is installed
 
    .EXAMPLE
        # Open an elevated PowerShell Session, import the module, and -
 
        PS C:\Users\zeroadmin> Install-DotNet472
     
#>
function Install-DotNet472 {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [string]$DownloadDirectory,

        [Parameter(Mandatory=$False)]
        [switch]$Restart
    )

    $Net472Check = Get-ChildItem "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release | ForEach-Object { $_ -ge 461808 }
    if ($Net472Check) {
        Write-Warning ".Net 4.7.2 (or higher) is already installed! Halting!"
        return
    }

    $DotNet472OfflineInstallerUrl = "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe"
    if (!$DownloadDirectory) {$DownloadDirectory = "$HOME\Downloads"}
    $OutFilePath = "$DownloadDirectory\NDP472-KB4054530-x86-x64-AllOS-ENU.exe"

    try {
        $WebClient = [System.Net.WebClient]::new()
        $WebClient.Downloadfile($DotNet472OfflineInstallerUrl, $OutFilePath)
        $WebClient.Dispose()
    }
    catch {
        Invoke-WebRequest -Uri $DotNet472OfflineInstallerUrl -OutFile $OutFilePath
    }

    if ($Restart) {
        & "$HOME\Downloads\NDP472-KB4054530-x86-x64-AllOS-ENU.exe" /q
    }
    else {
        & "$HOME\Downloads\NDP472-KB4054530-x86-x64-AllOS-ENU.exe" /q /norestart
    }
    
    while ($(Get-Process | Where-Object {$_.Name -like "*NDP472*"})) {
        Write-Host "Installing .Net Framework 4.7.2 ..."
        Start-Sleep -Seconds 5
    }

    Write-Host ".Net Framework 4.7.2 was installed successfully!" -ForegroundColor Green

    if (!$Restart) {
        Write-Warning "You MUST restart $env:ComputerName in order to use .Net Framework 4.7.2! Please do so at your earliest convenience."
    }
}