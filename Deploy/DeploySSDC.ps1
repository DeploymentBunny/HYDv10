#Deploy the entore Solution

#Set Vars
$Logpath = "C:\Setup\FABuilds\log.txt"
$SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
$VMlocation = "D:\VMs"
$VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx"

#Update the settings file
#C:\Setup\HYDv10\UpdateSettingsFile\Update-SettingsFile.ps1 -SettingsFile $SettingsFile

#Verify Host
C:\Setup\HYDv10\VeriFyBuildSetup\Verify-DeployServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Test the CustomSettings.xml for OSD data
C:\Setup\HYDv10\CheckConfig\CheckConfig.ps1 -SettingsFile $SettingsFile -LogPath $Logpath

#Deploy ADDS01
C:\Setup\HYDv10\TaskSequences\DeployADDS01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployADDS02.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy RRAS01
$Server = 'RRAS01'
$Roles = 'RRAS'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy RDGW01
$Server = 'RDGW01'
$Roles = 'RDGW'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy MGMT01
$Server = 'MGMT01'
$Roles = 'MGMT'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy DEPL01
$Server = 'DEPL01'
$Roles = 'DEPL'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy WSUS01
$Server = 'WSUS01'
$Roles = 'WSUS'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy SCVM01
$Server = 'SCVM01'
$Roles = 'SCVM'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy SCOM01
$Server = 'SCOM01'
$Roles = 'SCOM'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Deploy SCDP01
$Server = 'SCDP01'
$Roles = 'SCDP'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction

#Check log
Get-Content -Path $Logpath