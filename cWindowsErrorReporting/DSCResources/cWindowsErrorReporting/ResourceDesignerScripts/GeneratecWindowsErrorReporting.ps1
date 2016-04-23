$State = New-xDscResourceProperty -Name 'State' -Type 'String' -Attribute Key -ValidateSet 'Enabled','Disabled'

New-xDscResource -Name cWindowsErrorReporting -Property $State -ModuleName cWindowsErrorReporting -FriendlyName cWindowsErrorReporting -Path "C:\Git\DscModules\"