
# 示例1

$From = "src@abc.com"
$To = "dest@abc.com"

$Subject = "TestSubject" 
$Body = "TestBody"
$smtpServer = "mail.muchost.com"
$smtpPort = 25
$username = "src@abc.com"
$password = "myPassword"


$SMTPMessage = New-Object System.Net.Mail.MailMessage($From, $To, $Subject, $Body)
$SMTPClient = New-Object Net.Mail.SmtpClient($smtpServer, $SmtpPort) 
$SMTPClient.EnableSsl = $false 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($username, $password); 
$SMTPClient.Send($SMTPMessage)




# 示例2



$user = "lang.wang@slbcopower.com"
$PWord = ConvertTo-SecureString –String "这里是密码" –AsPlainText -Force
$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord
#Start-Sleep -Seconds 120 #这是暂停多久之后执行
$body=Get-Content "d:\log.txt" #这是从D盘内的log.txt获取里面的内容
Send-MailMessage -Subject "test" -Body $body -From $user -to 973447211@qq.com -SmtpServer smtp.263.net -Port 465 -UseSsl -Credential $user
#Stop-Computer #这是关机