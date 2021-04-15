
$connectTestResult = Test-NetConnection -ComputerName rrsfa.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"rrsfa.file.core.windows.net`" /user:`"Azure\rrsfa`" /pass:`"ywM9aOqRs1H1fT+98WaN88Bl7G1pvk+nfma00L42mOpnriz+7pLE4M3CM0uRrtkdn0aNt/x/u4AHA89tFx2tqg==`""
    # Mount the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\rrsfa.file.core.windows.net\sjusd" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}