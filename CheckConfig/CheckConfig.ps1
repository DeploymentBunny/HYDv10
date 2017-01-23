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
[xml]$Bootstrap = Get-Content $BootstrapFile -ErrorAction Stop

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop

#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$Domains = $Settings.settings.Domains.Domain
$return = foreach($Item in $Domains.Name){
    $Servers = $Settings.settings.Servers.Server | Where-Object -Property Active -EQ -Value $True
    foreach($ServerName in $Servers.Name){
        $CustomerData = $Settings.settings.Customers.Customer
        $CommonSettingData = $Settings.settings.CommonSettings.CommonSetting
        $ProductKeysData = $Settings.settings.ProductKeys.ProductKey
        $NetworksData = $Settings.settings.Networks.Network
        $DomainData = $Settings.settings.Domains.Domain | Where-Object -Property Name -EQ -Value $Item
        $ServerData = $Settings.settings.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName
        $NIC001 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property Name -EQ -Value NIC01
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
            VMMemory = ($VMMemory/1GB);
        }
        New-Object PSObject -Property $data
    }
}

foreach($obj in $return){
    Update-VIALog -Data "$($obj.ComputerName),$($obj.IPAddress)/$($obj.SubnetMask),$($obj.Gateway)"
}










