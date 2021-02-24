#Requires -Modules Get-MediaInfo
#Requires -Version 7
# 拆分长m4a和lrc，每小时为一个文件
$parent = join-path -path $(get-location).Path -ChildPath "output"

if (!(test-path -LiteralPath $parent)){
    New-Item -ItemType Directory -Force -Path $parent
}
function runQaac {
    param (
        [string]$start,
        [string]$end,
        [Parameter(Mandatory=$true)]
        [string]$new_name,
        [Parameter(Mandatory=$true)]
        [string]$source
    )
    $command = "&`"C:\Program Files (x86)\foobar2000\encoders\qaac64.exe`" --no-optimize`
     --threading -V 64 -N --copy-artwork $($start ? "--start $start" : '') $($end ? "--end $end" : '') -o `"$new_name`" `"$source`""
    Write-Host $command
    Invoke-Expression $command
}

$extension = ".m4a", ".lrc"
Get-ChildItem -File | Where-Object { $extension -contains $_.Extension } | `
ForEach-Object {
    
    $duration = (Get-MediaInfo $_.FullName).duration
    if ($_.Extension -eq '.m4a' -and ($duration -gt 60)) {
        $i = 0
        while ($duration -gt ($i * 60)) {
            $new_name = join-path -Path $parent -ChildPath ((Split-Path -LeafBase $_) + ".$($i + 1)" + $_.Extension)
            if ($duration -gt (($i + 1) * 60)) {
                runQaac -start "${i}:00:00" -end "$($i + 1):00:00" -new_name $new_name -source $_.FullName
            }
            else {
                runQaac -start "${i}:00:00" -new_name $new_name -source $_.FullName
            }
            $i ++
        }
        Write-Host "Split m4a $_"
    }
    elseif ($_.Extension -eq '.lrc') {
        $lrc = Get-Content -LiteralPath $_.FullName
        $result = New-Object System.Collections.Generic.List[String]
        $pattern = '\[(\d+):(\d+)\.(\d+)\](.*)'
        $i = 1
        foreach ($Line  in  $lrc) {    
            if ($Line -match $pattern) {
                $minutes = [convert]::ToInt32($Matches.1, 10)
                $second = [convert]::ToInt32($Matches.2, 10)
                $milis = [convert]::ToInt32($Matches.3, 10)
                $content = $Matches.4
                if ($minutes -ge ($i * 60)){
                    $new_name = join-path -Path $parent -ChildPath ((Split-Path -LeafBase $_) + ".$i" + $_.Extension)
                    $result | Out-File -Encoding UTF8 -LiteralPath $new_name
                    $i ++
                    $result.Clear()
                }
                $result.add(("[{0:D2}:{1:D2}.{2:D3}]{3}" -f ($minutes % 60), $second, $milis, $content))
            }
            elseif ($Line) {
                $result.add($Line)
                Write-Host "不是歌词行：$Line"
            }
        }
        if ($i -ne 1) {
            if ($result.Count -gt 0) {
                $new_name = join-path -Path $parent -ChildPath ((Split-Path -LeafBase $_) + ".$i" + $_.Extension)
                $result | Out-File -Encoding UTF8 -LiteralPath $new_name
            }
            Write-Host "Processed lrc: $_"
        }
    }
}