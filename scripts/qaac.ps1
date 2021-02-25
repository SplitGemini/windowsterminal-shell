#require -version 7
[CmdletBinding()]
param(
    [switch] $High,
    [switch] $Normalize,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
# 不支持wildcard
$output = join-path -path $(get-location).Path -ChildPath "output"
if (!(test-path -LiteralPath $output)){
    New-Item -ItemType Directory -Force -Path $output
}

$extension = '.opus', '.ogg', '.mp3', '.wav', '.flac', '.ape', '.m4a'
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_.FullName
    }
}

function RunInFile([string]$path) {
    Write-Host "Start transfer `"$Path`""
    #$newvid = [io.path]::ChangeExtension($out, '.m4a')
    qaac64.exe --no-optimize --threading -V ($High ? 91 : 64) ($Normalize ? '-N' : '') --copy-artwork -d $output $Path
    #Write-Host $command
    #Invoke-Expression $command
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        $path = $path -replace '`(\[|\]|\.|\*)' ,'$1'
        try {
            $path = Resolve-Path -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if ((Test-Path -LiteralPath $path -PathType Leaf) -and ($extension -contains (Get-Item -LiteralPath $Path).Extension)) {
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
