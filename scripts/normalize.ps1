[CmdletBinding()]
param(
    [Parameter(Position = 0,
        ValueFromRemainingArguments=$true)]
    [string[]] $Paths
)
# 不支持wildcard
$output = join-path -path $(get-location).Path -ChildPath "output"
if (!(test-path -LiteralPath $output)){
    New-Item -ItemType Directory -Force -Path $output
}

$extension = ".m4a", ".mp3", ".wav"
function RunInDir([string]$path) {
    Write-Host "Solving `"$path`""
    Get-ChildItem -LiteralPath $path -File | Where-Object { $extension -contains $_.Extension} | `
    ForEach-Object {
        RunInFile $_.FullName
    }
}

function RunInFile([string]$path) {
    $out = join-path -Path $output -ChildPath (Get-Item -LiteralPath $path).Name
    $newvid = [io.path]::ChangeExtension($out, '.m4a')
    Write-Host "Start normalize" $path
    ffmpeg -y -hide_banner -i $path -threads 8 -af "loudnorm=i=-23.0:lra=7.0:tp=-2.0:" -ar 48000 -vn $newvid
}

if ($Paths -and ($Paths.count -gt 0)) {
    foreach ($path in $Paths) {
        $path = $path -replace '`(\[|\]|\.|\*)' ,'$1'
        try {
            $path = Resolve-Path -LiteralPath $path
            # 获取后缀 另一种方法[System.IO.Path]::GetExtension
            if ((Test-Path -LiteralPath $path -PathType Leaf) -and ($extension -contains (Get-Item -LiteralPath $path).Extension)) {
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
