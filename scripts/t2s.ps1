[CmdletBinding()]
param(
    [Parameter(Position = 0,
        ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
$extension = ".lrc", ".srt", ".txt"
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_.FullName
    }
}

function RunInFile([string]$path) {
    Write-Host "Start transfer tranditional chinese to simplified chinese: `"$path`""
    cc -i $path -o $path
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        $path = $path -replace '`(\[|\]|\.|\*)' ,'$1'
        try {
            $path = Resolve-Path -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if ((Test-Path -LiteralPath $path -PathType Leaf) -and ($extension -contains (Get-ChildItem $Path).Extension)) {
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