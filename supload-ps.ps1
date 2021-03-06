
    <#
    .SYNOPSIS
    Script for upload files to cloud storage supported
    Cloud Files API (such as OpenStack Swift).
	
    !!!Version 0.1!!!
	
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
	.\supload-ps -user MyUser -key MyPassword TEST_DIR c:\Backup\text.txt
    .NOTES
    supload-ps.ps1 -u <USER> -k <KEY> <dest_dir> <src_path>
    .LINK

    Github repo: https://github.com/goodsmileduck/supload-ps
    #>

    param(
        [Parameter(Mandatory=$True, Position=1)]
        [string]$user,
		[Parameter(Mandatory=$True, Position=2)]
        [string]$key,
		[Parameter(Mandatory=$True, Position=3)]
		[string]$dest_dir,
		[Parameter(Mandatory=$True, Position=4)]
		[string]$src_path
		
		
    )
# Defaults
$auth_url="https://auth.selcdn.ru/"

$file=$src_path

#Вычисляем хеш
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($file))) -replace "-",""

#Определяем имя файла из пути
$filename = Split-Path $file -Leaf
#Формируем заголовки для процесса аутентификации
$headers_auth =  New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers_auth.Add("X-Auth-User", "$user")
$headers_auth.Add("X-Auth-Key", "$key")
#Хорошо бы это был Powershell >3 
if ($PSVersionTable.PSVersion.Major -gt 2){

#Отправляем запрос на аутентификацию


$response_auth = $null
    try {
        $response_auth = Invoke-WebRequest -Uri $auth_url -Method Get -Headers $headers_auth
    } 
    catch [System.Net.WebException] {
        $response_auth = $_.Exception.Response

    }
    catch {
        Write-Error $_.Exception
        return $null
    }
    if ($response_auth.StatusCode -match "204"){
        #auth is successful
        Write-Output "$(Get-Date –f o) Auth:Successful"
    } elseif ($response_auth.StatusCode -match "403"){
        Write-Error $upload.StatusCode "$(Get-Date –f o) Auth:Forbidden"
    } else {
        Write-Error $upload.StatusCode "$(Get-Date –f o) Auth:WTF!!!???"
    }
    

#Определяем url для загрузки
$upload_url = $response_auth.Headers."X-Storage-Url" + $dest_dir + "/" + $filename
#Формируем заголовок с токеном который получили
$headers =  New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Auth-Token", $response_auth.Headers."X-Auth-Token")
$headers.Add("etag", "$hash")
#Если хеш файла не совпадает получаем 503
$upload = Invoke-WebRequest -Uri $upload_url -Method Put -Headers $headers -InFile $file
if ($upload.StatusCode -match "201"){
    #Upload is successful
    Write-Output "$(Get-Date –f o) File $filename uploaded"
	} else {
	Write-Output "$(Get-Date –f o) File $filename upload failed"
	}
} else {
#Что же если это не 3 версия Powershell

$response_auth = [System.Net.WebRequest]::Create("$auth_url")
$response_auth.Headers.Add("X-Auth-User", "$user")
$response_auth.Headers.Add("X-Auth-Key", "$key")
$response = $response_auth.GetResponse();

if ([int]$response.StatusCode -match "204"){
        #auth is successful
        Write-Output "$(Get-Date –f o) Auth:Successful"
    } elseif ([int]$response.StatusCode -match "403"){
        Write-Error $upload.StatusCode "$(Get-Date –f o) Auth:Forbidden"
    } else {
        Write-Error $upload.StatusCode "$(Get-Date –f o) Auth:WTF!!!???"
    }
#Определяем url для загрузки
$upload_url = $response.Headers.get("X-Storage-Url") + $dest_dir + "/" + $filename
#Давайте попробуем все в этой жизни! И Скажем спасибо .NET v2
$req = [System.Net.WebRequest]::Create("$upload_url")
$req.Method = "PUT"
$req.SendChunked = $true
#Задаем загаловки с токеном и etag(проверка md5 после загрузки)
$req.Headers.Add("X-Auth-Token", $response.Headers.get("X-Auth-Token"))
$req.Headers.Add("etag", "$hash")
#Читаем фаил
$data = [System.IO.File]::ReadAllBytes("$file")
$req.ContentLength = $data.Length
$reqstream = $req.GetRequestStream()
$reqstream.Write($data, 0, $data.Length)
$reqstream.Close()
$resp = $req.GetResponse()
if ([int]$resp.StatusCode -match "201"){
    #Upload is successful
    Write-Output "$(Get-Date –f o) File $filename uploaded"
	} else {
	Write-Output "$(Get-Date –f o) File $filename upload failed"
}



}


