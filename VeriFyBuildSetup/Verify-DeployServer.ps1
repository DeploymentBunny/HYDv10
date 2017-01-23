#Verify 0.4
#Make sure this file is located in C:\Setup\HYDV7\Scripts

[cmdletbinding(SupportsShouldProcess=$true)]
Param
(
    [parameter(position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $SettingsFile,

    [parameter(position=1,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $BootstrapFile,

    [parameter(Position=2,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VHDImage,
    
    [parameter(Position=3,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VMlocation,

    [parameter(Position=4,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogPath = $LogPath,

    [parameter(Position=5,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    $Roles,

    [parameter(Position=6,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Server = $Server,

    [parameter(Position=7,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DomainName,

    [parameter(Position=8,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $FinishAction,

    [parameter(Position=9,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $VMSwitchName = 'NA',

    [parameter(Position=10,mandatory=$False)]
    [Switch]
    $KeepMountedMedia
)


#Read data from Bootstrap XML
Write-Verbose "Reading $BootstrapFile"
$Global:BootstrapFile = "C:\Setup\HYDv10\Config\Bootstrap.xml"
[xml]$Global:Bootstrap = Get-Content $BootstrapFile -ErrorAction Stop

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

#Read data from XML
Update-VIALog -Data "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile
$CustomerData = $Settings.settings.Customers.Customer
$CommonSettingData = $Settings.settings.CommonSettings.CommonSetting
$ProductKeysData = $Settings.settings.ProductKeys.ProductKey
$NetworksData = $Settings.settings.Networks.Network
$DomainData = $Settings.settings.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.settings.BuildServers.BuildServer | Where-Object -Property Name -EQ -Value $ServerName


#Verify VMSwitch
if(!(Test-VIAVMSwitchexistence -VMSwitchname $($CommonSettingData.VMSwitchName))){
        Update-VIALog -Data "The VMSwitch $($CommonSettingData.VMSwitchName) is missing, break" -Class Warning
        BREAK
    }else{
        Update-VIALog -Data "The VMSwitch $($CommonSettingData.VMSwitchName) exists"
    }
