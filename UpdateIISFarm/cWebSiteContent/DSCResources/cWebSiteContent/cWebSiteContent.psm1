Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$DestinationPath,

        [ValidateSet("MD5","RIPEMD160","SHA1","SHA256","SHA384","SHA512")]
        [System.String]$Checksum = "SHA1" # Hash algorithm used to compare files
    )

    If (Test-Path -Path $DestinationPath -PathType Leaf) {        

        Write-Verbose "The path $DestinationPath exists and it is a file"
        $FileHash = Get-ChildItem -Path $DestinationPath | Get-FileHash -Algorithm $Checksum 
    
        $ReturnValue = @{
            Algorithm = $($FileHash.Algorithm)
            Hash = $($FileHash.Hash)
            FileName = Split-Path -Path $($FileHash.Path) -Leaf
            DestinationPath = $($FileHash.Path)
        }

        $ReturnValue    
    }
    Else {

        Write-Verbose "The path $DestinationPath doesn't exist or is not a file"
        $ReturnValue = @{
            Algorithm = $null
            Hash = $null
            FileName = $null
            DestinationPath = $null
        }

        $ReturnValue
    }
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [System.String]$SourcePath,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$DestinationPath,

        [ValidateSet("MD5","RIPEMD160","SHA1","SHA256","SHA384","SHA512")]
        [System.String]$Checksum = "SHA1", # Hash algorithm used to compare files

        [System.Boolean]$Force = $false,    # Allows overwriting files in the destination with the same name as in the source but with different content (different hash)

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$WebAppPool
    )

    Write-Verbose "Stopping WebAppPool $WebAppPool."
    Stop-WebAppPool -Name $WebAppPool -ErrorAction SilentlyContinue

    # Waiting for the WebAppPool to be completely stopped
    While ((Get-WebAppPoolState -Name $WebAppPool).Value -ne "Stopped") {
        Write-Verbose "Waiting for the AppPool $WebAppPool to stop."
        Start-Sleep -Milliseconds 600
    }

    $DestinationDirectory = Split-Path -Path $DestinationPath -Parent

    If (-not (Test-Path -Path $DestinationDirectory -PathType Container)) { 
        Write-Verbose "Creating the parent directory for DestinationPath : $DestinationPath."
        New-Item -ItemType Directory -Path $DestinationDirectory -Force
    }

    Write-Verbose "Copying file $SourcePath to $DestinationDirectory."
    Try {
        Copy-Item -Path $SourcePath -Destination $DestinationPath -ErrorAction Stop -Force:$Force
    }
    Catch {
        Write-Error "$($_.Exception.Message)"
    }

    Write-Verbose "Starting WebAppPool $WebAppPool."
    Try {
        Start-WebAppPool -Name $WebAppPool -ErrorAction Stop
    }
    Catch {
        Throw "$($_.Exception.Message)"
    }
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [System.String]$SourcePath,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$DestinationPath,

        [ValidateSet("MD5","RIPEMD160","SHA1","SHA256","SHA384","SHA512")]
        [System.String]$Checksum = "SHA1", # Hash algorithm used to compare files

        [System.String]$WebAppPool
    )

    $DesiredState = Get-TargetResource -DestinationPath $SourcePath -Checksum $Checksum
    $CurrentState = Get-TargetResource -DestinationPath $DestinationPath -Checksum $Checksum
    
    $IsAlgorithmInDesiredState = $($CurrentState.Algorithm) -eq $($DesiredState.Algorithm)
    Write-Verbose "`$IsAlgorithmInDesiredState = $IsAlgorithmInDesiredState"

    $IsHashInDesiredState = $($CurrentState.Hash) -eq $($DesiredState.Hash)
    Write-Verbose "`$IsHashInDesiredState = $IsHashInDesiredState"

    $IsFileNameInDesiredState = $($CurrentState.FileName) -eq $($DesiredState.FileName)
    Write-Verbose "`$IsFileNameInDesiredState = $IsFileNameInDesiredState"

    $result = $IsAlgorithmInDesiredState -and $IsHashInDesiredState -and $IsFileNameInDesiredState
    $result
}

Export-ModuleMember -Function *-TargetResource
