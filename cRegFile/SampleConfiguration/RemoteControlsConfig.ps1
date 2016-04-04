$DevEnvironment = @{
    AllNodes = 
    @(
        @{
            NodeName = "Localhost"
            RegFileFolder = "C:\DSCConfigs\Files\"
        }
    )
}

Configuration RemoteControls
{
    param(
        [parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$Credential
    )
    Import-DscResource -ModuleName "PSDesiredStateConfiguration"
    Import-DscResource -ModuleName "cRegFile"

    Node $AllNodes.NodeName
    {
        File RemotesRegFile
        {
            DestinationPath = $($Node.RegFileFolder) + "RemotesKey.reg"
            SourcePath = "\\DevBox\Share\RemotesKey.reg"
            Ensure = "Present"
            Type = "File"
            Credential = $Credential
            Checksum = "SHA-1"
            Force = $true
            MatchSource = $true
        }
        cRegFile SupportedRemoteControls
        {
            key = "HKLM:\SYSTEM\CurrentControlSet\Services\HidIr\Remotes"
            RegFilePath = $($Node.RegFileFolder) + "RemotesKey.reg"
            DependsOn = "[File]RemotesRegFile"
        }
    }
}
RemoteControls -ConfigurationData $DevEnvironment -OutputPath "C:\DSCConfigs\RemoteControls\" -Credential (Get-Credential)
Start-DscConfiguration -Path "C:\DSCConfigs\RemoteControls" -Wait -Verbos