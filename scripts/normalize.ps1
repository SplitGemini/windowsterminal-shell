$extension = ".m4a", ".mp3", ".wav"
$output = join-path -path $(get-location).Path -ChildPath "output"

if (!(test-path -LiteralPath $output)){
    New-Item -ItemType Directory -Force -Path $output
}
Get-ChildItem -File | Where-Object { $extension -contains $_.Extension} | `
ForEach-Object { 
    $out = join-path -Path $output -ChildPath $_.Name
    $newvid = [io.path]::ChangeExtension($out, '.m4a')
    Write-Host "Start normalize" $_
    ffmpeg -y -hide_banner -i $_.FullName -threads 8 -af "loudnorm=i=-23.0:lra=7.0:tp=-2.0:" -ar 48000 -vn $newvid
}
Write-Host '完成'