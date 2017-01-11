#Deploy the entire Solution

#Read data from XML
$Global:SettingsFile = "C:\Setup\HYDv10\Config\ViaMonstra_MDT_LAB.xml"
[xml]$Global:Settings = Get-Content $SettingsFile -ErrorAction Stop

#Set Vars
$Global:DomainName = 'CORP'
$Global:Solution = "HYDv10"
$Global:Logpath = "$env:TEMP\HYDv10" + ".log"
$Global:VMlocation = "D:\VMs"
$Global:VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx"
$Global:MediaISO = 'C:\Setup\ISO\HYDV10.iso'

#Import-Modules
Import-Module -Global C:\Setup\Functions\VIAHypervModule.psm1
Import-Module -Global C:\Setup\Functions\VIAUtilityModule.psm1
Import-Module -Global C:\Setup\Functions\VIAXMLUtility.psm1

#Enable verbose for testing
$Global:VerbosePreference = "Continue"
#$Global:VerbosePreference = "SilentlyContinue"

#Update the settings file
C:\Setup\HYDv10\UpdateSettingsFile\Update-SettingsFile.ps1 -SettingsFile $SettingsFile

#Verify Host
C:\Setup\HYDv10\VeriFyBuildSetup\Verify-DeployServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath

#Test the CustomSettings.xml for OSD data
C:\Setup\HYDv10\CheckConfig\CheckConfig.ps1 -SettingsFile $SettingsFile -LogPath $Logpath

#Deploy VIADC01
$Global:Server = 'ADDS01'
$FinishAction = 'NONE'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server

#Deploy VIARDGW01
$Global:Server = 'RDGW01'
$Global:Roles = 'RDGW'
$FinishAction = 'NONE'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -Roles $Roles -FinishAction $FinishAction

#Deploy VIASNAT01
$Global:Server = 'SNAT01'
$Global:Roles = 'SNAT'
$FinishAction = 'NONE'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -Roles $Roles -FinishAction $FinishAction

#Deploy VIAMDT01
$Global:Server = 'MDT01'
$Global:Roles = 'DEPL'
$FinishAction = 'NONE'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -Roles $Roles -FinishAction $FinishAction

#Deploy WSUS01
$Global:Server = 'WSUS01'
$Global:Roles = 'WSUS'
$FinishAction = 'NONE'
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -Roles $Roles -FinishAction $FinishAction

#Check log
Get-Content -Path $Logpath
