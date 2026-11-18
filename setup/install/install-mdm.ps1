$repo    = "anefzaoui/misterdownloadmanager"
$tag     = (Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest").tag_name
$version = $tag -replace '^v', ''
$file    = "MisterDownloadManager-$version-setup.exe"

try {
  Invoke-WebRequest "https://github.com/$repo/releases/download/$tag/$file" -OutFile $file
} catch {
  Write-Host "download failed: $_"
}

try {
  Start-Process -FilePath $file -ArgumentList "/silent" -Wait
} catch {
  Write-Host "installation failed: $_"
}
