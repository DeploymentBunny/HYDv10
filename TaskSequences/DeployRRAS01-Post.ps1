[cmdletbinding(SupportsShouldProcess=$true)]
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
    $LogPath = $LogPath,

    [parameter(Position=4,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Roles,

    [parameter(Position=5,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Server,

    [parameter(Position=6,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $FinishAction,

    [parameter(Position=7,mandatory=$False)]
    [Switch]
    $KeepMountedMedia
)

##############

#Init
$Server = "RRAS01"
$ROle = "RRAS"
$Global:LogPath= "$env:TEMP\log.txt"

#Set start time
$StartTime = Get-Date

#Step Step
$Step = 0

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$ServerName = $Server
$DomainName = "Fabric"

#Action
$Step = 1 + $step
$Action = "Notify start"
$Data = "Server:$ServerName" + "," + "Step:$Step" + "," + "Action:$Action"
Update-VIALog -Data $Data
Start-VIASoundNotify

#Read data from XML
$Step = 1 + $step
$Action = "Reading $SettingsFile"
$Data = "Server:$ServerName" + "," + "Step:$Step" + "," + "Action:$Action"
Update-VIALog -Data $Data
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop
$CustomerData = $Settings.FABRIC.Customers.Customer
$CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
$ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
$NetworksData = $Settings.FABRIC.Networks.Network
$ServicesData = $Settings.FABRIC.Services.Service
$DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName

$NIC01 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property Name -EQ -Value NIC01
$NIC01RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC01.ConnectedToNetwork

$AdminPassword = $CommonSettingData.LocalPassword
$DomainInstaller = $DomainData.DomainAdmin
$DomainName = $DomainData.DomainAdminDomain
$DNSDomain = $DomainData.DNSDomain
$DomainAdminPassword = $DomainData.DomainAdminPassword
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)

#Sample 1

#Action
$Action = "Sample 1"
Update-VIALog -Data "Action: $Action"

$ExternalNIC = ($ServerData.Networkadapters.Networkadapter | where ConnectedToNetwork -eq 80c41589-c5fc-4785-a673-e8b08996cfc2).NAME
$ExternalIP = ($ServerData.Networkadapters.Networkadapter | where ConnectedToNetwork -eq 80c41589-c5fc-4785-a673-e8b08996cfc2).IPAddress

Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($ExternalNIC, $ExternalIP)

    # Disable all Public and Private Firewall rules. 
    Get-NetFirewallRule | where Profile -match "Domain" | Set-NetFirewallRule -Profile "Domain"
    Get-NetFirewallRule | where Profile -like "Any" | Set-NetFirewallRule -Profile "Domain"
    Get-NetFirewallRule | where Profile -like "Private" | Set-NetFirewallRule -Enabled False
    Get-NetFirewallRule | where Profile -like "Public" | Set-NetFirewallRule -Enabled False

    # Disable all Bindings on NIC02 (Get Name from XML)
    Get-NetAdapterBinding -Name "$ExternalNIC" | where ComponentID -ne "ms_tcpip" | Set-NetAdapterBinding -Enabled $false

    # Disable Dynamic DNS Registration for Exnternal interface - NIC02 (Get name from XML) 
    Set-DnsClient -InterfaceAlias $ExternalNIC -RegisterThisConnectionsAddress $false

    # Disable NETBIOS over TCP/IP on Internet NIC
    # (0)  Enable Netbios via DHCP
    # (1)   Enable Netbios
    # (2)   Disable Netbios
    (gwmi win32_networkadapterconfiguration | where IPAddress -EQ $ExternalIP).settcpipnetbios(2)

} -Credential $domainCred -ArgumentList $ExternalNIC, $ExternalIP



#Action
$Action = "Done"
Write-Output "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."

