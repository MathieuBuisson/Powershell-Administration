$MyData = 
@{
    AllNodes = 
    @(
        @{
            NodeName = "$env:computername"
            Role     = "WebServer"
        }
    )
}

Configuration UpdateWebSite
{
    Import-DscResource -ModuleName "PSDesiredStateConfiguration"

    node $AllNodes.Where{$_.Role -eq "WebServer"}.NodeName
    {
        File WebPageCopy
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            Recurse = $true
            MatchSource = $true
            Checksum = "SHA-1"
            SourcePath = "\\DESKTOP-IODTS6L\SiteContents"
            DestinationPath = "C:\inetpub\wwwroot"    
            Force = $true # To allows overwriting existing files
        }

    }
}

UpdateWebSite -ConfigurationData $MyData -OutputPath "C:\DSCConfigs\UpdateWebSite"