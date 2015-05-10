function Supload
{
    <#
    .SYNOPSIS
    Script for upload files to cloud storage supported
    Cloud Files API (such as OpenStack Swift).
	
    !!!Version 0.1 upload only one last file!!!
	
    Author: Stanislav Serebrennikov, Twitter: @Goodsmileduck
    License: 
    Required Dependencies: None
    Optional Dependencies: None
    Version: 0.1
    .DESCRIPTION
    Script for upload files to cloud storage supported
    Cloud Files API (such as OpenStack Swift).
    .PARAMETER -user
    
    .EXAMPLE
    .\supload-ps -user MyUser -key MyPassword TEST_DIR c:\Backup\ -onlylast
	.EXAMPLE
	.\supload-ps -user MyUser -key MyPassword TEST_DIR c:\Backup\text.txt
    .NOTES
    supload-ps.ps1 -u <USER> -k <KEY> <dest_dir> <src_path>
    .LINK

    Github repo: https://github.com/goodsmileduck/supload-ps
    #>
[CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, Position=1)]
        [string]$user,
		[Parameter(Mandatory=$True, Position=2)]
        [string]$key,
		[Parameter(Mandatory=$True, Position=3)]
		[string]$dest_dir,
		[Parameter(Mandatory=$True, Position=4)]
		[string]$src_path,
		[switch]$onlylast
		
    )
# Defaults
$auth_url="https://auth.selcdn.ru/"

if $onlylast
{
    $file = dir $src_path | sort CreationTime | Select -Last 1 -Exp fullname
}
else
{
    $file=$src_path
}
#Вычисляем хеш
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($file))) -replace "-",""

#Определяем имя файла из пути
$filename = Split-Path $file -Leaf
#Формируем заголовки для процесса аутентификации
$headers_auth =  New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers_auth.Add("X-Auth-User", "$user")
$headers_auth.Add("X-Auth-Key", "$key")

#Отправляем запрос на аутентификацию
$response_auth = Invoke-WebRequest -Uri $auth_url -Method Get -Headers $headers_auth

#Определяем url для загрузки
$upload_url = $response_auth.Headers."X-Storage-Url" + $dest_dir + "/" + $filename
#Формируем заголовок с токеном который получили
$headers =  New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Auth-Token", $response_auth.Headers."X-Auth-Token")
$headers.Add("etag", "$hash")

#Если хеш файла не совпадает получаем 503
$response = Invoke-WebRequest -Uri $upload_url -Method Put -Headers $headers -InFile $file

# Надо права администратора
#if ($response.StatusCode == 201)
#{
#New-EventLog –LogName Application –Source “Suplouad”
#Write-EventLog –LogName Application –Source “Supload” –EntryType Information –EventID 1 –Message “Файл $src_path успешно скопирован”
#}

Write-Output $response.StatusCode
}
supload