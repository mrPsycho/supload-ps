
$path="C:\"
$user=""
$key=""
$dest_dir=""
$backup_dir="C:\"
$command = ". C:\"
$today = (get-date).Date

$files = Get-ChildItem $path | where { $_.CreationTime.Date -eq $today }

		
foreach ($file in $files) {
$args = @()
$args += ("-user", $user)
$args += ("-key", $key)
$args += ("-dest_dir", $dest_dir)
$args += ("-src_path", $file.fullname)
$LogTime = Get-Date -Format "dd-MM-yyyy_hh-mm-ss"
    Invoke-Expression "$command $args | Out-File $backup_dir\$dest_dir-$LogTime.txt -Encoding UTF8"
}

