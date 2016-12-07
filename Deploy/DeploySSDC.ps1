#Deploy the entore Solution

#Set Vars
$Logpath = "C:\Setup\FABuilds\log.txt"
$SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
$VMlocation = "D:\VMs"
$VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx"

#Update the settings file
#C:\Setup\HYDv10\UpdateSettingsFile\Update-SettingsFile.ps1 -SettingsFile $SettingsFile

#Verify Host
#C:\Setup\HYDv10\VeriFyBuildSetup\Verify-DeployServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Test the CustomSettings.xml for OSD data
C:\Setup\HYDv10\CheckConfig\CheckConfig.ps1 -SettingsFile $SettingsFile -LogPath $Logpath

#Deploy ADDS01
C:\Setup\HYDv10\TaskSequences\DeployADDS01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployADDS02.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployRRAS01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployRDGW01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -Verbose

BREAK

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployDEPL01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployMGMT01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeployWSUS01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeploySCVM01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeploySCOM01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Deploy ADDS02
C:\Setup\HYDv10\TaskSequences\DeploySCDP01.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Check log
Get-Content -Path $Logpath