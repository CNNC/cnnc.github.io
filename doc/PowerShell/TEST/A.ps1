function add([int]$a,[int]$b) {
    $n = $a + $b
    “$a+$b=$n”
}

$a= Read-Host "请输入a的值"
$b= Read-Host "请输入b的值"

add $a $b