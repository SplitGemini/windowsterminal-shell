$extension = ".m4a", ".mp3", ".wav"
$output = join-path -path $(get-location).Path -ChildPath "output"
#$output = [Management.Automation.WildcardPattern]::Escape($output)
if (!(test-path -LiteralPath $output)){
    New-Item -ItemType Directory -Force -Path $output
}
Get-ChildItem -File | Where-Object { $extension -contains $_.Extension} | `
ForEach-Object { 
    $out = join-path $output -ChildPath $_.Name
    ffmpeg -y -hide_banner -i $_.FullName  -map_channel 0.0.1 -map_channel 0.0.0 -b:a 256k $out
}
Write-Host '完成'