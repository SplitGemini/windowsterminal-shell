$extension = ".m4a", ".mp3", ".mp4"
$output = join-path -path $(get-location).Path -ChildPath "output"
if (!(test-path -LiteralPath $output)){
    New-Item -ItemType Directory -Force -Path $output
}
Get-ChildItem -File | Where-Object { $extension -contains $_.Extension} | `
ForEach-Object { 
    $out = join-path -Path $output -ChildPath $_.Name
    Write-Host "Start remove metadata" $_
    ffmpeg -y -hide_banner -i $_.FullName -c copy -map_metadata -1 -map_chapters -1 $out
}
Write-Host '完成'
