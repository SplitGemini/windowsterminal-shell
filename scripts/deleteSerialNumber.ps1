[CmdletBinding()]
param(
    [Parameter(Position = 0,
        ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
# 不支持wildcard
$pattern = '(.*?)( \([0-9]+\)| - 副本| - 复制)+(\.[a-z0-9]{1,8})$'
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_
    }
}

function RunInFile([string]$path) {
    $new_name = join-path -Path (Split-Path $path.FullName) -ChildPath ($Path.name -replace $pattern ,'$1$3')
    if (!(test-path $new_name)){
        Rename-Item -LiteralPath $path $new_name
        write-host "rename `"$path`" to `"$new_name`""
    }
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        $path = [Management.Automation.WildcardPattern]::Unescape($path)
        try {
            $path = Convert-Path -LiteralPath $path
            $path = Get-Item -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if (!$path.PSIsContainer) {
                RunInFile $Path
            }
            else ($path.PSIsContainer){
                RunInDir $Path
            }
        }
        catch {
            Write-Host "`"$path`" doesn't exists or not surported. Error $_"
        }
    }
}
else {
    RunInDir $(get-location).Path
}


Write-Host '完成'
if (!$IsWindowsTerminal) {
    Read-Host "Press any key to continue."
}
