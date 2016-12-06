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
    $VMlocation = "D:\VMs"
)

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop

#Import Module
Import-Module C:\Setup\Functions\VIAHypervModule.psm1 -Force -ErrorAction Stop
Import-Module C:\Setup\Functions\VIADeployModule.psm1 -Force -ErrorAction Stop
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force -ErrorAction Stop

#Get data from XML
$ServerName = "BUILD01"
$DomainName = "Fabric"

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile
$CustomerData = $Settings.FABRIC.Customers.Customer
$CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
$ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
$NetworksData = $Settings.FABRIC.Networks.Network
$DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.FABRIC.BuildServers.BuildServer | Where-Object -Property Name -EQ -Value $ServerName


#Verify VMSwitch
if(!(Test-VIAVMSwitchexistence -VMSwitchname $($CommonSettingData.VMSwitchName))){
    Write-Warning "The VMSwitch $($CommonSettingData.VMSwitchName) is missing, break"
    BREAK
    }else{Write-Host -ForegroundColor Green "Ok."}


#Verify VMswitch is not Private
if((Get-VMSwitch -Name $($CommonSettingData.VMSwitchName)).SwitchType -eq 'Private'){
    Write-Warning "Switchtype is Private, change to Internal or External, will break"
    Break
    }else{Write-Host -ForegroundColor Green "Ok."}

#Check that the build machine will have access to the Fabric Network
$UplinkSwitchNetAdapter = Get-NetAdapter -Name *$($CommonSettingData.VMSwitchName)*
$UplinkSwitchNetAdapterSettings = Get-NetIPAddress -InterfaceIndex $UplinkSwitchNetAdapter.ifIndex | Where-Object AddressFamily -EQ IPv4

#Check IP
if($UplinkSwitchNetAdapterSettings.IPAddress -ne $ServerData.IPAddress){
    Write-Warning "Your IP on $($UplinkSwitchNetAdapter.Name) is $($UplinkSwitchNetAdapterSettings.IPAddress)"
    Write-Warning "It should be $($ServerData.IPAddress)"
    Write-Warning "Will break"
    Break
    }else{Write-Host -ForegroundColor Green "Ok."}

#Check PrefixLength
if($UplinkSwitchNetAdapterSettings.PrefixLength -ne $ServerData.PrefixLength){
    $CurrentSubnetMask = (Convert-Subnet -PrefixLength $UplinkSwitchNetAdapterSettings.PrefixLength).SubnetMask
    $ExpectedSubnetMask = (Convert-Subnet -PrefixLength $ServerData.PrefixLength).SubnetMask
    Write-Warning "Your Subnetmask on $($UplinkSwitchNetAdapter.Name) is $CurrentSubnetMask"
    Write-Warning "It should be $ExpectedSubnetMask"
    Write-Warning "Will break"
    Break
    }else{Write-Host -ForegroundColor Green "Ok."}
