#Requires -Version 2
function Get-ThreadInfo {

<#
.SYNOPSIS
   Obtains detailed performance information on threads in the specified process(es).

.DESCRIPTION
   Obtains detailed information on threads for the specified process(es).
   It gives the thread ID, user CPU time, system CPU time, its scheduling state and
   if the thread is waiting, the wait reason.

   This cmdlet expects process(es) either by ID (specified with the -ID parameter) or     by name (specified with the -Name parameter)

.PARAMETER ID
    To specify the process by its Process ID

.PARAMETER Name
    To specify all the processes which have a specific name.
    Accepts wildcards.

.PARAMETER ComputerName
    Gets the thread information on the specified computers. The default is the local computer.

    Type the NetBIOS name, an IP address, or a fully qualified domain name of one or more
    computers.

.EXAMPLE
   Get-ThreadInfo -ID 4372

   Obtains the thread information for the process which has the ID 4372.

.EXAMPLE
   Get-ThreadInfo -Name FlashPlayerPlugin* -ComputerName 10.0.0.184

   Obtains the thread information for all running instances of the Flash Player plugin
   on a remote computer with the IP address 10.0.0.184
#>

[cmdletbinding()]
param(
    [Parameter(ParameterSetName="ID")] 
    [int32[]]$ID,

    [Parameter(ParameterSetName="Name")]
    [string[]]$Name,

    [string[]]$ComputerName = "Localhost"
)

$Processes = Get-Process @PSBoundParameters 

Foreach ($Process in $Processes) {

    # Extracting the threads consuming CPU time from each process
    $ProcessThreads = $Process.Threads | Where-Object { $_.TotalProcessorTime.Ticks -ne 0 }
    $NumberofThreadsWithCPUTime = ($ProcessThreads | Measure-Object).count

    Foreach ($ProcessThread in $ProcessThreads) {

        # Building custom properties for the output objects

        $ObjProperties = [ordered]@{'ProcessName'=$Process.ProcessName
            'ProcessID'=$Process.Id
            'ThreadID'=$ProcessThread.Id
            'CPU Time (Sec)'=[math]::round((($ProcessThread.UserProcessorTime.ticks / $ProcessThread.TotalProcessorTime.ticks)*100),1)
            'User CPU Time (%)'=[math]::round((($ProcessThread.UserProcessorTime.ticks / $ProcessThread.TotalProcessorTime.ticks)*100),1)
            'System CPU Time (%)'=[math]::round((($ProcessThread.privilegedProcessorTime.ticks / $ProcessThread.TotalProcessorTime.ticks)*100),1)
            'State'=$ProcessThread.ThreadState
            }

        # Building a custom object from the list of properties above
        $CustomObj = New-Object -TypeName PSObject -Property $ObjProperties

        # Mapping the possible values of WaitReason to their meaning (source: MSDN)
        Switch ($ProcessThread.WaitReason)
            {
            EventPairHigh {$Wait_ReasonValue = "Waiting for event pair high.Event pairs are used to communicate with protected subsystems." ; break}
            EventPairLow { $Wait_ReasonValue = "Waiting for event pair low. Event pairs are used to communicate with protected subsystems." ; break}
            ExecutionDelay { $Wait_ReasonValue = "Thread execution is delayed." ; break}
            Executive { $Wait_ReasonValue = "The thread is waiting for the scheduler." ; break}
            FreePage { $Wait_ReasonValue = "Waiting for a free virtual memory page." ; break}
            LpcReceive { $Wait_ReasonValue = "Waiting for a local procedure call to arrive."; break}
            LpcReply { $Wait_ReasonValue = "Waiting for reply to a local procedure call to arrive." ; break}
            PageIn { $Wait_ReasonPropertyValue = "Waiting for a virtual memory page to arrive in memory." ; break}
            PageOut { $Wait_ReasonValue = "Waiting for a virtual memory page to be written to disk." ; break}
            Suspended { $Wait_ReasonValue = "Thread execution is suspended." ; break}
            SystemAllocation { $Wait_ReasonValue = "Waiting for a memory allocation for its stack." ; break}
            Unknown { $Wait_ReasonValue = "Waiting for an unknown reason." ; break}
            UserRequest { $Wait_ReasonValue = "The thread is waiting for a user request." ; break}
            VirtualMemory { $Wait_ReasonValue = "Waiting for the system to allocate virtual memory." ; break}

            Default { $Wait_ReasonValue = " " ; break }
        }

        # Adding the property "Wait Reason" to our custom object
        $CustomObj | Add-Member –MemberType NoteProperty –Name "Wait Reason" –Value $Wait_ReasonValue
        $CustomObj
        }
    }
}
