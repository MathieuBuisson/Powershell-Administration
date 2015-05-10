##Description : 

This module contains one cmdlet : **Restore-DfsrSysvol** .

It performs a non-authoritative or authoritative (if the **-Authoritative** parameter is used) resynchronization of DFSR replicated SYSVOL on one or more domain controllers.
	
The procedure followed by this cmdlet is explained in the following article : https://support.microsoft.com/kb/2218556
	
This is useful in the following scenarios :

    DFS Replication is used to replicate the Active Directory SYSVOL share  
    
    The SYSVOL folder is empty  
    
    The SYSVOL share is missing (not shared) on one or more domain controllers  
    
    The NETLOGON share is missing (not shared) on one or more domain controllers

This module requires Powershell version 4 (or later), the Activedirectory module, the Dfsr module and to be run as Administrator.

###CAUTION :

This module comes with no guarantee, use at your own risk.  
The modifications performed by this cmdlet can adversely affect your Active Directory domain.  
It should be tested first in a lab before running it in your production environment.

##Parameters :

**ReferenceDC :** To specify the FQDN (Fully Qualified Domain Name) of the domain controller which is considered as authoritative.  
This should be the domain controller which has the most up-to-date SYSVOL content.  
If not specified, this parameter defaults to the PDC emulator of the domain.

**DCToRestore :** To specify one or more domain controllers for which the SYSVOL needs to be resynchonized. If not specified, this parameter defaults to the FQDN of the local computer.

**Authoritative :** To perform an authoritative restore of the SYSVOL from the reference DC to all other domain controllers in the domain.  
If this parameter is used, the -DCToRestore parameter is not useful and not available.
