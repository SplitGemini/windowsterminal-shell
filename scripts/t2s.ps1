[CmdletBinding()]
param(
    [Parameter(Position = 0,
        ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
# 不支持wildcard
#转简体
$extension = ".lrc", ".srt", ".txt"
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_
    }
}

function RunInFile([Parameter(Mandatory = $true)]$path) {
    Write-Host "Start transfer tranditional chinese to simplified chinese: `"$path`""
    cc -i $path.FullName -o $path.FullName
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        # 逆转义，因为自动补全会自动转义，但是不太需要
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