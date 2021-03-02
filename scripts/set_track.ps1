#require -version 7
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
# 不支持wildcard

$extension = '.opus', '.ogg', '.mp3', '.wav', '.flac', '.ape', '.m4a'
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_
    }
}

function RunInFile([Parameter(Mandatory = $true)]$path,
                   [Parameter(Mandatory = $true)][int]$track) {
    Write-Host "Start transfer `"$Path`""
    #$newvid = [io.path]::ChangeExtension($out, '.m4a')
    $str = tageditor set track $track --file $Path.FullName | Out-String
    $bytes = [System.Text.Encoding]::GetEncoding('gbk').GetBytes($str)
    $nf = [System.Text.Encoding]::UTF8.GetString($bytes)
    write-host $nf
}

if ($Paths -and ($Paths.count -gt 0)) {
    $Paths = $Paths | Sort-Object Name
    foreach ($path in $Paths) {
        $path = [Management.Automation.WildcardPattern]::Unescape($path)
        try {
            $path = Convert-Path -LiteralPath $path
            $path = Get-Item -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if (!$path.PSIsContainer -and ($extension -contains $Path.Extension)) {
                RunInFile $Path
            }
            elseif ($path.PSIsContainer){
                RunInDir $Path
            }
            else {
                Write-Host "`"$path`" not surported."
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
