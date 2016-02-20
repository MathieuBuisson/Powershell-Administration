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
    Import-DscResource -ModuleName "cWebSiteContent"

    node $AllNodes.Where{$_.Role -eq "WebServer"}.NodeName
    {
        cWebSiteContent www.mat.lab
        {
            SourcePath = "C:\Users\Mathieu\Desktop\Index.html"
            DestinationPath = "C:\inetpub\wwwroot\Index.html"
            Checksum = 'SHA256'
            Force = $true
            WebAppPool = "DefaultAppPool"
        }
    }
}

UpdateWebSite -ConfigurationData $MyData -OutputPath "C:\DSCConfigs\UpdateWebSite"