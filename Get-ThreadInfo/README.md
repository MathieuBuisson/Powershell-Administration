##Description :

This module contains one cmdlet : **Get-ThreadInfo**.

It obtains detailed information on threads for the specified process(es).  
It gives the thread ID, user CPU time, system CPU time, its scheduling state and if the thread is waiting, the wait reason. 

This cmdlet expects process(es) either by ID (specified with the -ID parameter) or by name (specified with the **-Name** parameter)

Requires Powershell version 2 or later.

##Parameters :

**ID :** To specify the process by its Process ID

**Name :** To specify all the processes which have a specific name.  
Accepts wildcards.

**ComputerName :** Gets the thread information on the specified computers.  
The default is the local computer.  
Type the NetBIOS name, an IP address, or a fully qualified domain name of one or more computers.
