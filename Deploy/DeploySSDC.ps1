#Deploy the entire Solution

#Read data from XML
$Global:SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
[xml]$Global:Settings = Get-Content $SettingsFile -ErrorAction Stop

#Set Vars
$Global:Solution = "HYDv10"
$Global:Logpath = "$env:TEMP\HYDv10" + ".log"
$Global:VMlocation = "D:\VMs"
$Global:VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx"
$Global:MediaISO = 'C:\Setup\ISO\HYDV10.iso'

#Import-Modules
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Update the settings file
C:\Setup\HYDv10\UpdateSettingsFile\Update-SettingsFile.ps1 -SettingsFile $SettingsFile

#Verify Host
C:\Setup\HYDv10\VeriFyBuildSetup\Verify-DeployServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Test the CustomSettings.xml for OSD data
C:\Setup\HYDv10\CheckConfig\CheckConfig.ps1 -SettingsFile $SettingsFile -LogPath $Logpath

#Deploy ADDS01
$Global:Server = 'ADDS01'
$Global:Roles = 'ADDS','DHCP'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployADDS01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
$Global:Server = 'ADDS02'
$Global:Roles = 'ADDS','DHCP'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployADDS02.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy RRAS01
$Global:Server = 'RRAS01'
$Global:Roles = 'RRAS'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy RDGW01
$Global:Server = 'RDGW01'
$Global:Roles = 'RDGW'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy MGMT01
$Global:Server = 'MGMT01'
$Global:Roles = 'MGMT'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy DEPL01
$Global:Server = 'DEPL01'
$Global:Roles = 'DEPL'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy WSUS01
$Global:Server = 'WSUS01'
$Global:Roles = 'WSUS'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCVM01
$Global:Server = 'SCVM01'
$Global:Roles = 'SCVM'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCOM01
$Global:Server = 'SCOM01'
$Global:Roles = 'SCOM'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy SCDP01
$Global:Server = 'SCDP01'
$Global:Roles = 'SCDP'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction -KeepMountedMedia

#Deploy TEST01
$Global:Server = 'TEST01'
$Global:Roles = 'NONE'
$FinishAction = 'Shutdown'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Roles $Roles -Server $Server -FinishAction $FinishAction  -KeepMountedMedia

#Check log
Get-Content -Path $Logpath
