$Key = New-xDscResourceProperty -Name Key -Type String -Attribute Key -Description "Name of the registry key to configure recursively"
$RegFilePath = New-xDscResourceProperty -Name RegFilePath -Type String -Attribute Write -Description "Path of the .reg file representing the desired state of the registry key"

New-xDscResource -Name cRegFile -Property $Key,$RegFilePath -ModuleName cRegFile -FriendlyName cRegFile -Path C:\GitHub\Powershell-Administration\