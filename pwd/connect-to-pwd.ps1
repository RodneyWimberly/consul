Clear-Host
.\set-pwd-variables.ps1

Push-Location $Env:ScriptPath
Start-Ssh --Node $Env:Worker
Start-Ssh --Node $Env:Manager
Pop-Location

function Start-Ssh {
    param($Node = "")
    Write-Verbose " --> Opening ssh to " + $Env:PwdUrl + " for Node " + $Node
    Start-Process --FilePath "putty.exe" --ArgumentList [ $Node + "@" + $Env:PwdUrl ]
}
