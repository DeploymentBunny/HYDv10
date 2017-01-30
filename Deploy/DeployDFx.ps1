#Deploy the entire Solution

#Read data from Bootstrap XML
$Global:BootstrapFile = "C:\Setup\HYDv10\Config\Bootstrap_DEMOHOST03.xml"
[xml]$Global:Bootstrap = Get-Content $BootstrapFile -ErrorAction Stop

#Read data from XML
$Global:SettingsFile = "C:\Setup\HYDv10\Config\corp.viamonstra.com.DFBooks.xml"
[xml]$Global:Settings = Get-Content $SettingsFile -ErrorAction Stop

#Set Vars
$Global:Solution = $Bootstrap.BootStrap.CommonSettings.CommonSetting.Solution
$Global:Logpath = $Bootstrap.BootStrap.CommonSettings.CommonSetting.Logpath
$Global:DomainName = $Settings.Settings.Customers.Customer.PrimaryDomainName
$Global:VMlocation = ($Bootstrap.BootStrap.Folders.Folder | Where-Object -Property Name -EQ -Value VMFolder).path
$MediaISOData = $Bootstrap.BootStrap.ISOs.ISO | Where-Object -Property Name -EQ -Value HYDv10.iso
$Global:MediaISO = $MediaISOData.Path + '\' + $MediaISOData.Name
$Global:VMSwitchName = $Bootstrap.BootStrap.CommonSettings.CommonSetting.VMSwitch

#Disable verbose for testing
#$Global:VerbosePreference = "Continue"
$Global:VerbosePreference = "SilentlyContinue"

#Import-Modules
Import-Module -Global C:\Setup\Functions\VIAHypervModule.psm1 -Force
Import-Module -Global C:\Setup\Functions\VIAUtilityModule.psm1 -Force
Import-Module -Global C:\Setup\Functions\VIAXMLUtility.psm1 -Force
Import-Module -Global C:\Setup\Functions\VIADeployModule.psm1 -Force

#Enable verbose for testing
$Global:VerbosePreference = "Continue"
#$Global:VerbosePreference = "SilentlyContinue"

#Update the settings file
#Only for production
#C:\Setup\HYDv10\UpdateSettingsFile\Update-SettingsFile.ps1 -SettingsFile $SettingsFile

#Verify Host
C:\Setup\HYDv10\VeriFyBuildSetup\Verify-DeployServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -VMSwitchName $VMSwitchName

#Test the CustomSettings.xml for OSD data
C:\Setup\HYDv10\CheckConfig\CheckConfig.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -VMSwitchName $VMSwitchName

#Deploy ADDS01
#$Global:Server = 'ADDS01'
#$FinishAction = 'NONE'
#$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
#$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
#C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -KeepMountedMedia

#Deploy ADDS02
#$Global:Server = 'ADDS02'
#$FinishAction = 'Shutdown'
#$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
#$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
#C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -KeepMountedMedia

#Deploy TEST01
$Global:Server = 'TEST01'
$Global:Roles = 'NONE'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy SNAT01
$Global:Server = 'SNAT01'
$Global:Roles = 'SNAT'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy RDGW01
$Global:Server = 'RDGW01'
$Global:Roles = 'RDGW'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy MGMT01
$Global:Server = 'MGMT01'
$Global:Roles = 'MGMT'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy DEPL01
$Global:Server = 'DEPL01'
$Global:Roles = 'DEPL'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy MDT01
$Global:Server = 'MDT01'
$Global:Roles = 'MDT'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy WSUS01
$Global:Server = 'WSUS01'
$Global:Roles = 'WSUS'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy SCVM01
$Global:Server = 'SCVM01'
$Global:Roles = 'SCVM'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy SCOM01
$Global:Server = 'SCOM01'
$Global:Roles = 'SCOM'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy SCDP01
$Global:Server = 'SCDP01'
$Global:Roles = 'SCDP'
$FinishAction = 'Shutdown'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy vHOST01
$Global:Server = 'vHOST01'
$Global:Roles = 'vConverged'
$FinishAction = 'NONE'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy vHOST02
$Global:Server = 'vHOST02'
$Global:Roles = 'vConverged'
$FinishAction = 'NONE'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy vHOST03
#Note:Nano
$Global:Server = 'vHOST03'
$Global:Roles = 'vConverged'
$FinishAction = 'NONE'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_NANO_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia

#Deploy vHOST04
#Note:Nano
$Global:Server = 'vHOST04'
$Global:Roles = 'vConverged'
$FinishAction = 'NONE'
$VHDImageData = $Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property name -EQ -Value WS2016_Datacenter_UEFI_GUI_EVAL_Fabric.vhdx
$Global:VHDImage = $VHDImageData.Path + '\' + $VHDImageData.Name
C:\Setup\HYDv10\TaskSequences\DeployFABRICServer.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server -VMSwitchName $VMSwitchName -FinishAction $FinishAction -Roles $Roles -KeepMountedMedia







#Check log
Get-Content -Path $Logpath

BREAK

#Deploy the VM's, in correct order
$ServerToDeploy = $Settings.FABRIC.Servers.Server | Where-Object Active -EQ $true | Where-Object Deploy -EQ $true | Where-Object Virtual -EQ $true | Sort-Object -Property DeployOrder
$ServerToDeploy | Select-Object Name,DeployOrder
foreach($obj in $ServerToDeploy){
    $Global:Server = $obj.Name
    #$FinishAction = 'NONE'
    C:\Setup\HYDv10\TaskSequences\DeployADDS01.ps1 -BootstrapFile $BootstrapFile -SettingsFile $SettingsFile -VHDImage $VHDImage -VMlocation $VMlocation -LogPath $Logpath -DomainName $DomainName -Server $Server
}



