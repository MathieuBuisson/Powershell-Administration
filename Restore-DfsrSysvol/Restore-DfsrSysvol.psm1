#Requires -Version 4
#Requires -Modules ActiveDirectory,dfsr
#Requires -RunAsAdministrator

function Restore-DfsrSysvol {
<#
.SYNOPSIS
    Performs a non-authoritative or authoritative restore of DFSR replicated SYSVOL on one or more 
domain controllers.

.DESCRIPTION
    Performs a non-authoritative or authoritative (if the -Authoritative parameter is used) resynchronization of DFSR replicated SYSVOL on one or more domain controllers.
	
	The procedure followed by this cmdlet is explained in the following article : https://support.microsoft.com/kb/2218556
	
	This is useful in the following scenarios :
			DFS Replication is used to replicate the Active Directory SYSVOL Share
		    The SYSVOL folder is empty
			The SYSVOL share is missing (not shared) on one or more domain controllers
			The NETLOGON share is missing (not shared) on one or more domain controllers

.PARAMETER ReferenceDC
    To specify the FQDN (Fully Qualified Domain Name) of the domain controller which is considered as authoritative.
	This should be the domain controller which has the most up-to-date SYSVOL content.
	
	If not specified, this parameter defaults to the PDC emulator of the domain.

.PARAMETER DCToRestore
    To specify one or more domain controllers for which the SYSVOL needs to be resynchonized.
	If not specified, this parameter defaults to the FQDN of the local computer.

.PARAMETER Authoritative
    To perform an authoritative restore of the SYSVOL from the reference DC to all other domain controllers in the domain.
	If this parameter is used, the -DCToRestore parameter is not useful and not available.

.EXAMPLE 
    Restore-DfsrSysvol -ReferenceDC ADDC08.domain.com

    Performs a non-authoritative restore of the SYSVOL on the local computer, synchronizing from the domain controller ADDC08.domain.com.

.EXAMPLE
    Restore-DfsrSysvol -Authoritative -ReferenceDC ADDC08.domain.com
    
	Performs an authoritative restore of the SYSVOL for all domain controllers, synchronizing from the domain controller ADDC08.domain.com.
	
.LINK
	https://support.microsoft.com/kb/2218556
#>
    [cmdletbinding(DefaultParameterSetName="NonAuthoritative",
    SupportsShouldProcess,
    ConfirmImpact = 'High')]
    param(
        [string]$ReferenceDC = (Get-ADDomain).PDCEmulator,    
    
        [Parameter(ValueFromPipeline=$False, # disabling pipeline input to make sure that each operation is done simultaneously on the domain controllers
        ParameterSetName = "NonAuthoritative",
        Position=0)]
        [string[]]$DCToRestore = [System.Net.Dns]::GetHostByName((hostname)).HostName,
        
        [Parameter(ParameterSetName = "Authoritative")]
        [switch]$Authoritative
    )

    Begin {
        $ReferenceDcDN = (Get-ADDomainController -Identity $ReferenceDC).ComputerObjectDN
        $AuthoritativeExcludedDCList = Get-ADDomain | Select-Object -ExpandProperty ReplicaDirectoryServers |
        Where { $_ -ne "$ReferenceDC" }
    }

    Process {
        # Non-Authoritative restore
        if (-not ($Authoritative)) {

            if ($PSCmdlet.ShouldProcess($DCTorestore)) {

                Foreach ($DC in $DCToRestore) {
                    Write-Verbose "`$DC is : $DC"
                    $DcDN = (Get-ADDomainController -Identity $DC).ComputerObjectDN
                    Write-Verbose "`$DcDN is : $DcDN"
                    $SysvolSettingsObj = Get-ADObject "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,$DcDN" -Properties msDFSR-Enabled
                    Write-Verbose $SysvolSettingsObj

                    # Disabling replication of the Sysvol for each DC to restore
                    $SysvolSettingsObj.'msDFSR-Enabled' = $False
                    Set-ADObject -Instance $SysvolSettingsObj
                    $DfsrEnabled = $SysvolSettingsObj."msDFSR-Enabled"
                    Write-Verbose "DFSR Enabled on $DC is : $DfsrEnabled "            

                    Try {
                        Invoke-Command -ComputerName $DC -ScriptBlock {Start-Process repadmin -ArgumentList "/syncall /APed" -NoNewWindow -Wait} -ErrorAction Stop
                    }
                    Catch {
                        Write-Warning $_.Exception.Message
                        Continue
                    }
                }
                Foreach ($DC in $DCToRestore) {
                    Update-DfsrConfigurationFromAD -ComputerName $DC -Verbose
                }
                Foreach ($DC in $DCToRestore) {
                    Write-Verbose "`$DC is : $DC"
                    $DcDN = (Get-ADDomainController -Identity $DC).ComputerObjectDN
                    Write-Verbose "`$DcDN is : $DcDN"
                    $SysvolSettingsObj = Get-ADObject "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,$DcDN" -Properties msDFSR-Enabled
                    Write-Verbose $SysvolSettingsObj

                    # Re-enabling replication of the Sysvol for each DC to restore
                    $SysvolSettingsObj.'msDFSR-Enabled' = $True
                    Set-ADObject -Instance $SysvolSettingsObj
                    $DfsrEnabled = $SysvolSettingsObj."msDFSR-Enabled"
                    Write-Verbose "DFSR Enabled on $DC is : $DfsrEnabled "

                    Try {
                        Invoke-Command -ComputerName $DC -ScriptBlock {Start-Process repadmin -ArgumentList "/syncall /APed" -NoNewWindow -Wait} -ErrorAction Stop
                    }
                    Catch {
                        Write-Warning $_.Exception.Message
                        Continue
                    }
                }
                Foreach ($DC in $DCToRestore) {
                    Update-DfsrConfigurationFromAD -ComputerName $DC -Verbose
                }
            }
        } # End of Non-Authoritative restore procedure
        Else {
            # Authoritative restore

            if ($PSCmdlet.ShouldProcess($AuthoritativeExcludedDCList)) {

                $RefDCSysvolSettingsObj = Get-ADObject "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,$ReferenceDcDN" -Properties msDFSR-Enabled,msDFSR-options
                Write-Verbose $RefDCSysvolSettingsObj

                # Disabling replication of the Sysvol for each DC to restore
                $RefDCSysvolSettingsObj.'msDFSR-Enabled' = $False
                $RefDCSysvolSettingsObj.'msDFSR-options' = 1
                Set-ADObject -Instance $RefDCSysvolSettingsObj
                $RefDCDfsrEnabled = $RefDCSysvolSettingsObj."msDFSR-Enabled"
                Write-Verbose "DFSR Enabled on $DC is : $RefDCDfsrEnabled "            
                $RefDCDFSROptions = $RefDCSysvolSettingsObj."msDFSR-options"
                Write-Verbose "DFSR Options on $DC is : $RefDCDFSROptions "
    
                Foreach ($DC in $AuthoritativeExcludedDCList) {

                    Write-Verbose "`$DC is : $DC"
                    $DcDN = (Get-ADDomainController -Identity $DC).ComputerObjectDN
                    Write-Verbose "`$DcDN is : $DcDN"
                    $SysvolSettingsObj = Get-ADObject "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,$DcDN" -Properties msDFSR-Enabled
                    Write-Verbose $SysvolSettingsObj

                    # Disabling replication of the Sysvol for all DCs except for the reference DC
                    $SysvolSettingsObj.'msDFSR-Enabled' = $False
                    Set-ADObject -Instance $SysvolSettingsObj
                    $DfsrEnabled = $SysvolSettingsObj."msDFSR-Enabled"
                    Write-Verbose "DFSR Enabled on $DC is : $DfsrEnabled "            

                    Try {
                        Invoke-Command -ComputerName $DC -ScriptBlock {Start-Process repadmin -ArgumentList "/syncall /APed" -NoNewWindow -Wait} -ErrorAction Stop
                    }
                    Catch {
                        Write-Warning $_.Exception.Message
                        Continue
                    }
                }
                Try {
                    Invoke-Command -ComputerName $ReferenceDC -ScriptBlock { Restart-Service -Name dfsr }
                }
                Catch {
                    Write-Error $_.Exception.Message
                    Exit
                }
                # Re-enabling replication of the Sysvol for the authoritative DC
                $RefDCSysvolSettingsObj.'msDFSR-Enabled' = $True            
                Set-ADObject -Instance $RefDCSysvolSettingsObj
                $RefDCDfsrEnabled = $RefDCSysvolSettingsObj."msDFSR-Enabled"
                Write-Verbose "DFSR Enabled on $DC is : $RefDCDfsrEnabled "            

                Try {
                    Invoke-Command -ComputerName $ReferenceDC -ScriptBlock {Start-Process repadmin -ArgumentList "/syncall /APed" -NoNewWindow -Wait} -ErrorAction Stop
                }
                Catch {
                    Write-Warning $_.Exception.Message
                    Continue
                }
                Update-DfsrConfigurationFromAD -ComputerName $ReferenceDC -Verbose

                Foreach ($DC in $AuthoritativeExcludedDCList) {
                    Write-Verbose "`$DC is : $DC"
                    Try {
                        Invoke-Command -ComputerName $DC -ScriptBlock { Restart-Service -Name dfsr }
                    }
                    Catch {
                        Write-Error $_.Exception.Message
                        Continue
                    }                
                    $DcDN = (Get-ADDomainController -Identity $DC).ComputerObjectDN
                    Write-Verbose "`$DcDN is : $DcDN"
                    $SysvolSettingsObj = Get-ADObject "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,$DcDN" -Properties msDFSR-Enabled
                    Write-Verbose $SysvolSettingsObj

                    # Re-enabling replication of the Sysvol for all DCs except for the reference DC
                    $SysvolSettingsObj.'msDFSR-Enabled' = $True
                    Set-ADObject -Instance $SysvolSettingsObj
                    $DfsrEnabled = $SysvolSettingsObj."msDFSR-Enabled"
                    Write-Verbose "DFSR Enabled on $DC is : $DfsrEnabled "            
                }
                Update-DfsrConfigurationFromAD -ComputerName $AuthoritativeExcludedDCList -Verbose
            }
        }
    }
    End {
    }
}