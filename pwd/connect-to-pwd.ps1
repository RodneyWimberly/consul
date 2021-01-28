Clear-Host
.\set-pwd-variables.ps1


function Start-Ssh {
    param($Node = "")
    Write-Host " --> Opening ssh to " & $Env:PwdUrl & " for Node " & $Node
    Start-Process --FilePath "putty.exe" --ArgumentList  $Node & "@" & $Env:PwdUrl
}

Push-Location $Env:ScriptPath
Start-Ssh $Env:Worker
Start-Ssh $Env:Manager
Pop-Location
