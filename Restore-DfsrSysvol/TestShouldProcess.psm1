
function Test {  
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'High')]  
    param(
        [Parameter(ValueFromPipeline = $True)]
        [string[]]$DCTorestore
    )  
    Begin {}
    Process {  
        if ($PSCmdlet.ShouldProcess($DCTorestore)) {  
            "Do all the stuff"
        }        
    }
    End {}  
}  
      
#"DC1.mat.lab","DC2mat.lab" | Test -WhatIf

