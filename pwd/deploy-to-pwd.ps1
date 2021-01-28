Clear-Host
.\set-pwd-variables.ps1

Push-Location $Env:ScriptPath
Run-Remote-Script --Node $Env:Worker
Run-Remote-Script --Node $Env:Manager
Pop-Location

function Run-Remote-Script {
    param($Node = "")
    Write-Verbose " --> Opening ssh to " + $Env:PwdUrl + " for Node " + $Node
    Start-Process --FilePath "putty.exe" --ArgumentList [  "-m " + $Env:RemoteCommand, $Node + "@" + $Env:PwdUrl ]
}
