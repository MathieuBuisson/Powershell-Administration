$DevEnvironment = @{
    AllNodes = 
    @(
        @{
            NodeName = "Localhost"
        }
    )
}

Configuration DisableWER
{
    param()

    Import-DscResource -ModuleName "cWindowsErrorReporting"

    Node $AllNodes.NodeName
    {
        cWindowsErrorReporting Disabled
        {
            State = "Disabled"
        }
    }
}
DisableWER -ConfigurationData $DevEnvironment -OutputPath "C:\DSCConfigs\DisableWER\"
