#XML设置

$xmldata = [xml](Get-Content D:\Home\cnnc.github.io\doc\PowerShell\xml\employee.xml)

# 访问和更新节点

# 获取employee中的参数
$employee = $xmldata.staff.employee | Where-Object { $_.Name -match "Tobias Weltner"}


# 设置employee的function
$employee.function = "vacation"
$xmldata.staff.employee | Format-Table -AutoSize


$xmldata.SelectNodes(   "staff/employee")


# 创建一个 XML定位:
$xpath = [System.XML.XPath.XPathDocument]`
[System.IO.TextReader][System.IO.StringReader]`
(Get-Content employee.xml | out-string)
$navigator = $xpath.CreateNavigator()
 
# 输出Hanover子公司的最后一位员工
$query = "/staff[@branch='Hanover']/employee[last()]/Name"
$navigator.Select($query) | Format-Table Value
 
# 输出Hanover子公司的除了Tobias Weltner之外的所有员工，
$query = "/staff[@branch='Hanover']/employee[Name!='Tobias Weltner']"
$navigator.Select($query) | Format-Table Value



# 属性是定义在一个XML标签中的信息，如果你想查看结点的属性，可以使用get_Attributes()方法：
$xmldata.staff.get_Attributes()

# 使用GetAttribute()方法来查询一个特定的属性：
$xmldata.staff.GetAttribute("branch")

#使用SetAttribute()方法来指定新的属性，或者更新（重写）已有的属性。
$xmldata.staff.SetAttribute("branch", "New York")
$xmldata.staff.GetAttribute("branch")



# 加载XML文本文件:
$xmldata = [xml](Get-Content employee.xml)
# 创建新的结点:
$newemployee = $xmldata.CreateElement("employee")
$newemployee.set_InnerXML( `
"<Name>Bernd Seiler</Name><function>expert</function>")
# 插入新结点:
$xmldata.staff.AppendChild($newemployee)
# 验证结果:
$xmldata.staff.employee



# 保存XML文件
$xmldata.Save(“$env:temp\updateddata.xml”)



# 预定视图
Get-Process | Format-Table -view Priority
Get-Process | Format-Table -view StartTime


## 使用一行命令即可重新格式化文本，让xml方便阅读：
$xmldata.get_OuterXML().Replace("<", "`t<").Replace(">", ">`t").Replace(">`t`t<", ">`t<").Split("`t") | `
ForEach-Object {$x=0}{ If ($_.StartsWith("</")) {$x--} `
ElseIf($_.StartsWith("<")) { $x++}; (" " * ($x)) + $_; `
if ($_.StartsWith("</")) { $x--} elseif `
($_.StartsWith("<")) {$x++} }

# 如果你想在一列中输出定义在XML文件中的所有的视图，Format-Table命令足矣，然后选择你想在摘要中显示的属性。
[xml]$file = Get-Content "$pshome\dotnettypes.format.ps1xml" `
$file.Configuration.ViewDefinitions.View | `
Format-Table Name, {$_.ViewSelectedBy.TypeName}
 

<# 接下来我们会提取出XML文件中所有的必须的信息。首先对视图按照ViewSelectedBy.TypeName排序，
接着根据criterion（标准）来分组。你也可以按照只匹配出一次确定的对象类型来排序。
你只需要那些值得在-view参数中指定的，存在多个对象类型的视图。#>

[xml]$file = Get-Content "$pshome\dotnettypes.format.ps1xml"
$file.Configuration.ViewDefinitions.View |
Sort-Object {$_.ViewSelectedBy.TypeName} |
Group-Object {$_.ViewSelectedBy.TypeName} |
Where-Object { $_.Count -gt 1} |
ForEach-Object { $_.Group} |
Format-Table Name, {$_.ViewSelectedBy.TypeName}, `
@{expression={if ($_.TableControl) { "Table" } elseif `
($_.ListControl) { "List" } elseif ($_.WideControl) { "Wide" } `
elseif ($_.CustomControl) { "Custom" }};label="Type"} -wrap