[CmdletBinding()]
param(
    [Parameter(Position = 0,
        ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
# 不支持wildcard
#转繁体
$extension = ".lrc", ".srt", ".txt"
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_.FullName
    }
}

function RunInFile([string]$path) {
    Write-Host "Start transfer simplified chinese to tranditional chinese: `"$path`""
    cc -e t -i $path -o $path
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        $path = $path -replace '`(\[|\]|\.|\*)' ,'$1'
        try {
            $path = Resolve-Path -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if ((Test-Path -LiteralPath $path -PathType Leaf) -and ($extension -contains (Get-Item $Path).Extension)) {
                RunInFile $Path
            }
            elseif (Test-Path -LiteralPath $path -PathType Container){
                RunInDir $Path
            }
            else {
                Write-Host "`"$path`" doesn't exists or not surported."
            }
        }
        catch {
            Write-Host "Error $_ : when proceed `"$path`"."
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