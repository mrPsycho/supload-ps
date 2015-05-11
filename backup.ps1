param(
    [Parameter(Mandatory=$True, Position=1)]
    [string]$path,
	[Parameter(Mandatory=$True, Position=2)]
    [string]$user,
	[Parameter(Mandatory=$True, Position=3)]
    [string]$key,
	[Parameter(Mandatory=$True, Position=4)]
	[string]$dest_dir
	)
$today = (get-date).Date

$files = Get-ChildItem $path | where { $_.CreationTime.Date -eq $today }

		
foreach ($file in $files) {
$args = @()
$args += ("-user", $user)
$args += ("-key", $key)
$args += ("-dest_dir", $dest_dir)
$args += ("-src_path", $file.fullname)
$command = ". C:\Users\Stanislav\Documents\GitHub\supload-ps\supload-ps.ps1"

    Invoke-Expression "$command $args"
}

