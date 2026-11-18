$repo    = "crmne/zapfast"
$tag     = (Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest").tag_name
$file    = "zapfast-$tag-x86_64-pc-windows-msvc.msi"

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
