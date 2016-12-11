#Deploy the entire Solution

#Read data from XML
$SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop

#Set Vars
$Global:Solution = "HYDv10"
$Global:Logpath = "$env:TEMP\HYDv10" + ".log"
$VMlocation = "D:\VMs"
$VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx"

#Import-Modules
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Update the settings file
C:\Setup\HYDv10\UpdateSettingsFile\Update-SettingsFile.ps1 -SettingsFile $SettingsFile

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
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy RDGW01
$Server = 'RDGW01'
$Roles = 'RDGW'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy MGMT01
$Server = 'MGMT01'
$Roles = 'MGMT'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy DEPL01
$Server = 'DEPL01'
$Roles = 'DEPL'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy WSUS01
$Server = 'WSUS01'
$Roles = 'WSUS'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCVM01
$Server = 'SCVM01'
$Roles = 'SCVM'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCOM01
$Server = 'SCOM01'
$Roles = 'SCOM'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCDP01
$Server = 'SCDP01'
$Roles = 'SCDP'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCDP01
$Server = 'TEST01'
$Roles = 'NONE'
$FinishAction = 'Shutdown'

C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction  -KeepMountedMedia


#Check log
Get-Content -Path $Logpath
