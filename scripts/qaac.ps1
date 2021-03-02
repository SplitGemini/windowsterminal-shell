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
        RunInFile $_
    }
}

function RunInFile([Parameter(Mandatory = $true)]$path) {
    Write-Host "Start transfer `"$Path`""
    #$newvid = [io.path]::ChangeExtension($out, '.m4a')
    if ($Path.Extension -ne '.m4a') {
        $cover = join-path -path $output -ChildPath cover.jpg
        $str = tageditor extract cover --output-file $cover --file $Path.FullName | Out-String
        $bytes = [System.Text.Encoding]::GetEncoding('gb2312').GetBytes($str)
        $nf = [System.Text.Encoding]::UTF8.GetString($bytes)
        write-host $nf
        $shouldDeleteCover = $true
        if (!(test-path -LiteralPath $cover)) {
            $Directory = [Management.Automation.WildcardPattern]::Escape($Path.DirectoryName)
            if (test-path -Path ($Directory + '\*.jpg')) {
                $cover = [Management.Automation.WildcardPattern]::Unescape((convert-path ($Directory + '\*.jpg')))
                $shouldDeleteCover = $false
            }
        }
        qaac64.exe --no-optimize --threading -V ($High ? 91 : 64) ($Normalize ? '-N' : '') --artwork $cover -d $output $Path.FullName
        #Write-Host $command
        #Invoke-Expression $command
        if ($shouldDeleteCover -and (test-path -LiteralPath $cover)) {
            remove-item -LiteralPath $cover
        }
    }
    else {
        qaac64.exe --no-optimize --threading -V ($High ? 91 : 64) ($Normalize ? '-N' : '') --copy-artwork -d $output $Path.FullName
    }
}

if ($Paths -and ($Paths.count -gt 0)) {
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
    write-host (Read-Host "Press any key to continue.")
}
Read-Host