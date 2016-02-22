$DevEnvironment = @{
    AllNodes = 
    @(
        @{
            NodeName                   = "*"
            PsDscAllowPlainTextPassword= $True
            Role                       = "WebServer"
            SourcePath                 = "\\DevBox\SiteContents\Index.html"
            DestinationPath            = "C:\inetpub\wwwroot\Index.html"
            Checksum                   = 'SHA256'
            Force                      = $True
            WebAppPool                 = "DefaultAppPool"
        }
        @{
            NodeName = "WebServer1"
        }
        @{
            NodeName = "WebServer2"
        }
    )
}

Configuration UpdateWebSite
{
    param(
        [parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$Credential
    )
    Import-DscResource -ModuleName "PSDesiredStateConfiguration"
    Import-DscResource -ModuleName "cWebSiteContent"

    Node $AllNodes.Where{$_.Role -eq "WebServer"}.NodeName
    {
        cWebSiteContent www.mat.lab
        {
            SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Checksum = $Node.Checksum
            Force = $Node.Force
            WebAppPool = $Node.WebAppPool
        }
    }
    Node WebServer2
    {
        WaitForAll WaitForWebServer1
        {
            NodeName = "WebServer1"
            ResourceName = "[cWebSiteContent]www.mat.lab"
            RetryIntervalSec = 4
            RetryCount = 5
            PsDscRunAsCredential = $Credential
        }
    }
}

UpdateWebSite -ConfigurationData $DevEnvironment -OutputPath "C:\DSCConfigs\UpdateWebSite" -Credential (Get-Credential)
Start-DscConfiguration -Path "C:\DSCConfigs\UpdateWebSite" -ComputerName WebServer1,WebServer2
