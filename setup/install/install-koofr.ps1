try {
  Invoke-WebRequest "https://app.koofr.net/dl/apps/win"
} catch {
  Write-Host "download failed: $_"
}

try {
  Start-Process -FilePath $file -ArgumentList "/silent" -Wait
} catch {
  Write-Host "installation failed: $_"
}
