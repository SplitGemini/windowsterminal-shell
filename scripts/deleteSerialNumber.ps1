[CmdletBinding()]
param(
    [Parameter(Position = 0,
        ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
$pattern = '(.*?)( \([0-9]+\)| - 副本| - 复制)+(\.[a-z0-9]{1,8})$'
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_.FullName
    }
}

function RunInFile([string]$path) {
    $new_name = join-path -Path (Split-Path $path) -ChildPath ((Get-ChildItem $Path).name -replace $pattern ,'$1$3')
    if (!(test-path $new_name)){
        Rename-Item -LiteralPath $path $new_name
        write-host "rename `"$path`" to `"$new_name`""
    }
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        $path = $path -replace '`(\[|\]|\.|\*)' ,'$1'
        try {
            $path = Resolve-Path -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                RunInFile $Path
            }
            elseif (Test-Path -LiteralPath $path -PathType Container){
                RunInDir $Path
            }
            else {
                Write-Host "`"$path`" doesn't exists."
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
