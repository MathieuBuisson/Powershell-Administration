$DevEnvironment = @{
    AllNodes = 
    @(
        @{
            NodeName = "Localhost"
        }
    )
}

Configuration RemoteControls
{
    param()
    Import-DscResource -ModuleName "cRegFile"

    Node $AllNodes.NodeName
    {
        cRegFile SupportedRemoteControls
        {
            key = "HKLM:\SYSTEM\CurrentControlSet\Services\HidIr\Remotes"
            RegFilePath = "C:\DSCConfigs\Files\RemotesKey.reg"
        }
    }
}
RemoteControls -ConfigurationData $DevEnvironment -OutputPath "C:\DSCConfigs\RemoteControls\"
Start-DscConfiguration -Path "C:\DSCConfigs\RemoteControls" -Wait -Verbose
