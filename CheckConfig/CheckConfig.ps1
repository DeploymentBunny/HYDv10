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

#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$log = "$env:TEMP\$ServerName" + ".log"

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile

$Domains = $Settings.FABRIC.Domains.Domain
foreach($DomainName in $Domains.Name){

    $Servers = $Settings.FABRIC.Servers.Server
    foreach($ServerName in $Servers.Name){
        $CustomerData = $Settings.FABRIC.Customers.Customer
        $CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
        $ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
        $NetworksData = $Settings.FABRIC.Networks.Network
        $DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
        $ServerData = $Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName
        $NIC001 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property id -EQ -Value NIC01
        $NIC001RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC001.ConnectedToNetwork
        $AdminPassword = $CommonSettingData.LocalPassword
        $DomainInstaller = $DomainData.DomainAdmin
        $DomainName = $DomainData.DomainAdminDomain
        $DNSDomain = $DomainData.DNSDomain
        $DomainAdminPassword = $DomainData.DomainAdminPassword
        $VMMemory = [int]$ServerData.Memory * 1024 * 1024
        $VMSwitchName = $CommonSettingData.VMSwitchName

        $Data = [ordered]@{
            ComputerName = $ServerData.ComputerName;
            IPAddress = $NIC001.IPAddress;
            SubnetMask = $NIC001RelatedData.SubNet;
            Gateway = $NIC001RelatedData.Gateway;
            VMSwitch = $VMSwitchName;
            VMMemory = $VMMemory;
        }

        $data
    }
}











