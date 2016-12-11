#Verify 0.4
#Make sure this file is located in C:\Setup\HYDV7\Scripts

Param
(
    [parameter(position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $SettingsFile = "C:\Setup\FABuilds\FASettings.xml",

    [parameter(Position=1,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx",
    
    [parameter(Position=2,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VMlocation = "D:\VMs",

    [parameter(Position=3,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogPath
)

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop

#Import Module
Import-Module C:\Setup\Functions\VIAHypervModule.psm1 -Force -ErrorAction Stop
Import-Module C:\Setup\Functions\VIADeployModule.psm1 -Force -ErrorAction Stop
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force -ErrorAction Stop

#Set Vars
$Global:Solution = "HYDv10"
$Global:Logpath = "$env:TEMP\HYDv10" + ".log"

#Get data from XML
$ServerName = "BUILD01"
$DomainName = "Fabric"

#Read data from XML
Update-VIALog -Data "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile
$CustomerData = $Settings.FABRIC.Customers.Customer
$CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
$ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
$NetworksData = $Settings.FABRIC.Networks.Network
$DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.FABRIC.BuildServers.BuildServer | Where-Object -Property Name -EQ -Value $ServerName


#Verify VMSwitch
if(!(Test-VIAVMSwitchexistence -VMSwitchname $($CommonSettingData.VMSwitchName))){
        Update-VIALog -Data "The VMSwitch $($CommonSettingData.VMSwitchName) is missing, break" -Class Warning
        BREAK
    }else{
        Update-VIALog -Data "The VMSwitch $($CommonSettingData.VMSwitchName) exists"
    }
