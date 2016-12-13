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
$Server = "SCVM01"
$ROle = "SCVM"
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

#Action
$Action = "Set Automatic Logical NetworkCreation - Disable"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost
    Set-SCVMMServer -AutomaticLogicalNetworkCreationEnabled $false -LogicalNetworkMatch "FirstDNSSuffixLabel" -BackupLogicalNetworkMatch "VirtualNetworkSwitchName"
} -Credential $domainCred

#Action
$Action = "Add SVC_SPF_SA to SCVMM Admin Role"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null
    $CurrentDomain = $env:USERDOMAIN
    $SPFSAccount = "SVC_SPF_SA"
    $userRole = Get-SCUserRole -Name "Administrator"
    Set-SCUserRole -UserRole $userRole -Description "Administrator User Role" -AddMember @("$CurrentDomain\$SPFSAccount")
} -Credential $domainCred

#Action
$Action = "Create SCVMM Administrator RunAs Account"
$AccountName = "SVC_SCVMM_AA"
$SVC_SCVMM_AAUserName = ($Settings.Fabric.Domains.Domain.DomainAccounts.DomainAccount  | Where-Object -Property Name -EQ -Value $AccountName).Name
$SVC_SCVMM_AAPW = ($Settings.Fabric.Domains.Domain.DomainAccounts.DomainAccount | Where-Object -Property Name -EQ -Value $AccountName).PW
$SVC_SCVMM_AAAccountDescription = ($Settings.Fabric.Domains.Domain.DomainAccounts.DomainAccount | Where-Object -Property Name -EQ -Value $AccountName).AccountDescription

Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SVC_SCVMM_AAUserName,$SVC_SCVMM_AAPW,$SVC_SCVMM_AAAccountDescription)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null
    $CurrentDomain = $env:USERDOMAIN
    $SecurePassword = ConvertTo-SecureString $SVC_SCVMM_AAPW -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$CurrentDomain\$SVC_SCVMM_AAUserName", $SecurePassword
    New-SCRunAsAccount -Name $SVC_SCVMM_AAAccountDescription -Credential $Credential -Description $SVC_SCVMM_AAAccountDescription
} -Credential $domainCred -ArgumentList $SVC_SCVMM_AAUserName,$SVC_SCVMM_AAPW,$SVC_SCVMM_AAAccountDescription


#Action
$Action = "Create OOB RunAs Account"
$SCVMMOOBAccount = ($ServicesData | Where-Object Name -EQ SCVMM2016).config.OOBAccountName
$SCVMMOOBAccountDescr = ($ServicesData | Where-Object Name -EQ SCVMM2016).config.OOBAccountDescr
$SCVMMOOBAccountPW = ($ServicesData | Where-Object Name -EQ SCVMM2016).config.OOBAccountPW
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SCVMMOOBAccount,$SCVMMOOBAccountDescr,$SCVMMOOBAccountPW)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null
    $SecurePassword = ConvertTo-SecureString $SCVMMOOBAccountPW -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SCVMMOOBAccount, $SecurePassword
    New-SCRunAsAccount -Name $SCVMMOOBAccountDescr -Credential $Credential
} -Credential $domainCred -ArgumentList $SCVMMOOBAccount,$SCVMMOOBAccountDescr,$SCVMMOOBAccountPW

#Action
$Action = "Add PXE Server"
$ServerToAdd = ($Settings.FABRIC.Servers.Server | Where-Object Name -EQ DEPL01).ComputerName
$RunAsAccount = $SVC_SCVMM_AAUserName

Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($ServerToAdd,$RunAsAccount)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    Add-SCPXEServer -ComputerName $ServerToAdd -Credential (Get-SCRunAsAccount | Where-Object UserName -EQ $RunAsAccount)

} -Credential $domainCred -ArgumentList $ServerToAdd,$RunAsAccount

#Action
$Action = "Add WSUS Server without sync"
$ServerToAdd = ($Settings.FABRIC.Servers.Server | Where-Object Name -EQ WSUS01).ComputerName
$RunAsAccount = $SVC_SCVMM_AAUserName

Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($ServerToAdd,$RunAsAccount)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    Add-SCUpdateServer -ComputerName $ServerToAdd -Credential (Get-SCRunAsAccount | Where-Object UserName -EQ $RunAsAccount) -TCPPort 8530

} -Credential $domainCred -ArgumentList $ServerToAdd,$RunAsAccount

#Action
$Action = "Create Host Groups"
Update-VIALog -Data "Action: $Action"
$SCVMHostGroups = "Production","Lab","Gateway","Replica","Management"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SCVMHostGroups)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null
    foreach($obj in $SCVMHostGroups){
        New-SCVMHostGroup -Name $obj
    }
} -Credential $domainCred -ArgumentList (,$SCVMHostGroups)

#Action
$Action = "Create SMB3 Port Class"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SCVMHostGroups)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    New-SCVirtualNetworkAdapterNativePortProfile -Name "SMB3" -Description "" -AllowIeeePriorityTagging $true -AllowMacAddressSpoofing $false -AllowTeaming $false -EnableDhcpGuard $false -EnableGuestIPNetworkVirtualizationUpdates $false -EnableIov $false -EnableIPsecOffload $false -EnableRouterGuard $false -EnableVmq $false -MinimumBandwidthWeight "80"
    New-SCPortClassification -Name "SMB3"

} -Credential $domainCred -ArgumentList (,$SCVMHostGroups)

#Action
$Action = "Create Uplink Port Switch and Profile for UplinkSwitch"
Update-VIALog -Data "Action: $Action"
$SCVMMUplinkPortFrofileName = "UpLinkPortProfile"
$SCVMMUplinkPortFrofileNameDescription = "Uplink Port Profile"
$SCVMMlogicalSwitchName = "UplinkSwitch"
$SCVMMUplinkPortProfileSet = "UpLinkPortProfileSet"
$SwitchUplinkMode = "Team"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SCVMMUplinkPortFrofileName,$SCVMMUplinkPortFrofileNameDescription,$SCVMMlogicalSwitchName,$SCVMMUplinkPortProfileSet,$SwitchUplinkMode)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    #Create Uplink Port Profile
    $SCVMMdefinition = @()

    New-SCNativeUplinkPortProfile -Name $SCVMMUplinkPortFrofileName -Description $SCVMMUplinkPortFrofileNameDescription -LogicalNetworkDefinition $SCVMMdefinition -EnableNetworkVirtualization $true -LBFOLoadBalancingAlgorithm "HostDefault" -LBFOTeamMode "SwitchIndependent"

    #Create Uplink Logical Switch
    $SCVMMvirtualSwitchExtensions = @()
    $SCVMMvirtualSwitchExtensions += Get-SCVirtualSwitchExtension -Name "Microsoft Windows Filtering Platform"
    $SCVMMlogicalSwitch = New-SCLogicalSwitch -Name $SCVMMlogicalSwitchName -Description "" -EnableSriov $false -SwitchUplinkMode $SwitchUplinkMode -VirtualSwitchExtensions $SCVMMvirtualSwitchExtensions
    $SCVMMnativeProfile = Get-SCNativeUplinkPortProfile -Name $SCVMMUplinkPortFrofileName
    New-SCUplinkPortProfileSet -Name $SCVMMUplinkPortProfileSet -LogicalSwitch $SCVMMlogicalSwitch -NativeUplinkPortProfile $SCVMMnativeProfile

    #Add Port Classes
    $SCVMMlogicalSwitch = Get-SCLogicalSwitch -Name $SCVMMlogicalSwitchName

    #Add Port SMB3
    $SCVMMportClassification = Get-SCPortClassification -Name "SMB3"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "SMB3"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "SMB3" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Host management
    $SCVMMportClassification = Get-SCPortClassification -Name "Host management"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Host management"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Host management" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Host Cluster Workload
    $SCVMMportClassification = Get-SCPortClassification -Name "Host Cluster Workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Cluster"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Host Cluster Workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Low bandwidth
    $SCVMMportClassification = Get-SCPortClassification -Name "Low bandwidth"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Low Bandwidth Adapter"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Low bandwidth" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Live migration
    $SCVMMportClassification = Get-SCPortClassification -Name "Live migration  workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Live migration"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Live migration workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Guest Dynamic IP
    $SCVMMportClassification = Get-SCPortClassification -Name "Guest Dynamic IP"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Guest Dynamic IP"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Guest Dynamic IP" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Medium bandwidth
    $SCVMMportClassification = Get-SCPortClassification -Name "Medium bandwidth"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Medium Bandwidth Adapter"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Medium bandwidth" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class High bandwidth
    $SCVMMportClassification = Get-SCPortClassification -Name "High bandwidth"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "High Bandwidth Adapter"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "High bandwidth" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class iSCSI workload
    $SCVMMportClassification = Get-SCPortClassification -Name "iSCSI workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "iScsi"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "iSCSI workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Network load balancing
    $SCVMMportClassification = Get-SCPortClassification -Name "Network load balancing"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Network load balancer NIC Profile"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Network load balancing" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

} -Credential $domainCred -ArgumentList $SCVMMUplinkPortFrofileName,$SCVMMUplinkPortFrofileNameDescription,$SCVMMlogicalSwitchName,$SCVMMUplinkPortProfileSet,$SwitchUplinkMode


#Action
$Action = "Create Uplink Port Switch and Profilefor UplinkSwitch SET"
Update-VIALog -Data "Action: $Action"
$SCVMMUplinkPortFrofileName = "UpLinkPortProfileSET"
$SCVMMUplinkPortFrofileNameDescription = "Uplink Port Profile SET"
$SCVMMlogicalSwitchName = "UplinkSwitchSET"
$SCVMMUplinkPortProfileSet = "UpLinkPortProfileSetSET"
$SwitchUplinkMode = "EmbeddedTeam"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SCVMMUplinkPortFrofileName,$SCVMMUplinkPortFrofileNameDescription,$SCVMMlogicalSwitchName,$SCVMMUplinkPortProfileSet,$SwitchUplinkMode)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    #Create Uplink Port Profile
    $SCVMMdefinition = @()

    New-SCNativeUplinkPortProfile -Name $SCVMMUplinkPortFrofileName -Description $SCVMMUplinkPortFrofileNameDescription -LogicalNetworkDefinition $SCVMMdefinition -EnableNetworkVirtualization $true -LBFOLoadBalancingAlgorithm "HostDefault" -LBFOTeamMode "SwitchIndependent"

    #Create Uplink Logical Switch
    $SCVMMvirtualSwitchExtensions = @()
    $SCVMMvirtualSwitchExtensions += Get-SCVirtualSwitchExtension -Name "Microsoft Windows Filtering Platform"
    $SCVMMlogicalSwitch = New-SCLogicalSwitch -Name $SCVMMlogicalSwitchName -Description "" -EnableSriov $false -SwitchUplinkMode $SwitchUplinkMode -VirtualSwitchExtensions $SCVMMvirtualSwitchExtensions
    $SCVMMnativeProfile = Get-SCNativeUplinkPortProfile -Name $SCVMMUplinkPortFrofileName
    New-SCUplinkPortProfileSet -Name $SCVMMUplinkPortProfileSet -LogicalSwitch $SCVMMlogicalSwitch -NativeUplinkPortProfile $SCVMMnativeProfile

    #Add Port Classes
    $SCVMMlogicalSwitch = Get-SCLogicalSwitch -Name $SCVMMlogicalSwitchName

    #Add Port SMB3
    $SCVMMportClassification = Get-SCPortClassification -Name "SMB3"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "SMB3"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "SMB3" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Host management
    $SCVMMportClassification = Get-SCPortClassification -Name "Host management"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Host management"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Host management" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Host Cluster Workload
    $SCVMMportClassification = Get-SCPortClassification -Name "Host Cluster Workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Cluster"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Host Cluster Workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Low bandwidth
    $SCVMMportClassification = Get-SCPortClassification -Name "Low bandwidth"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Low Bandwidth Adapter"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Low bandwidth" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Live migration
    $SCVMMportClassification = Get-SCPortClassification -Name "Live migration  workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Live migration"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Live migration workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Guest Dynamic IP
    $SCVMMportClassification = Get-SCPortClassification -Name "Guest Dynamic IP"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Guest Dynamic IP"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Guest Dynamic IP" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Medium bandwidth
    $SCVMMportClassification = Get-SCPortClassification -Name "Medium bandwidth"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Medium Bandwidth Adapter"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Medium bandwidth" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class High bandwidth
    $SCVMMportClassification = Get-SCPortClassification -Name "High bandwidth"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "High Bandwidth Adapter"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "High bandwidth" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class iSCSI workload
    $SCVMMportClassification = Get-SCPortClassification -Name "iSCSI workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "iScsi"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "iSCSI workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Class Network load balancing
    $SCVMMportClassification = Get-SCPortClassification -Name "Network load balancing"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Network load balancer NIC Profile"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Network load balancing" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

} -Credential $domainCred -ArgumentList $SCVMMUplinkPortFrofileName,$SCVMMUplinkPortFrofileNameDescription,$SCVMMlogicalSwitchName,$SCVMMUplinkPortProfileSet,$SwitchUplinkMode

#Action
$Action = "Create Uplink Port Switch and Profile for UplinkSwitch Management"
Update-VIALog -Data "Action: $Action"
$SCVMMUplinkPortFrofileName = "UplinkPortProfileMGM"
$SCVMMUplinkPortFrofileNameDescription = "Uplink Port Profile for Management"
$SCVMMlogicalSwitchName = "UplinkSwitchMGM"
$SCVMMUplinkPortProfileSet = "UpLinkPortProfileSetMGM"
$SwitchUplinkMode = "Team"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($SCVMMUplinkPortFrofileName,$SCVMMUplinkPortFrofileNameDescription,$SCVMMlogicalSwitchName,$SCVMMUplinkPortProfileSet,$SwitchUplinkMode)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    #Create Uplink Port Profile
    $SCVMMdefinition = @()

    New-SCNativeUplinkPortProfile -Name $SCVMMUplinkPortFrofileName -Description $SCVMMUplinkPortFrofileNameDescription -LogicalNetworkDefinition $SCVMMdefinition -EnableNetworkVirtualization $true -LBFOLoadBalancingAlgorithm "HostDefault" -LBFOTeamMode "SwitchIndependent"

    #Create Uplink Logical Switch
    $SCVMMvirtualSwitchExtensions = @()
    $SCVMMvirtualSwitchExtensions += Get-SCVirtualSwitchExtension -Name "Microsoft Windows Filtering Platform"
    $SCVMMlogicalSwitch = New-SCLogicalSwitch -Name $SCVMMlogicalSwitchName -Description "" -EnableSriov $false -SwitchUplinkMode $SwitchUplinkMode -VirtualSwitchExtensions $SCVMMvirtualSwitchExtensions
    $SCVMMnativeProfile = Get-SCNativeUplinkPortProfile -Name $SCVMMUplinkPortFrofileName
    New-SCUplinkPortProfileSet -Name $SCVMMUplinkPortProfileSet -LogicalSwitch $SCVMMlogicalSwitch -NativeUplinkPortProfile $SCVMMnativeProfile

    #Add Port Classes
    $SCVMMlogicalSwitch = Get-SCLogicalSwitch -Name $SCVMMlogicalSwitchName

    #Add Port Class Host management
    $SCVMMportClassification = Get-SCPortClassification -Name "Host management"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Host management"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Host management" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

    #Add Port Host Cluster Workload
    $SCVMMportClassification = Get-SCPortClassification -Name "Host Cluster Workload"
    $SCVMMnativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -Name "Cluster"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "Host Cluster Workload" -PortClassification $SCVMMportClassification -LogicalSwitch $SCVMMlogicalSwitch -VirtualNetworkAdapterNativePortProfile $SCVMMnativeProfile

} -Credential $domainCred -ArgumentList $SCVMMUplinkPortFrofileName,$SCVMMUplinkPortFrofileNameDescription,$SCVMMlogicalSwitchName,$SCVMMUplinkPortProfileSet,$SwitchUplinkMode

#Action
$Action = "Create all MGM Logical Networks"
Update-VIALog -Data "Action: $Action"
$SCVMMallHostGroupsName = "All Hosts"
foreach($item in $NetworksData){
    $SCVMMlogicalNetworkName = $item.name
    $SCVMMallSubnetVlanSubnet = ($item.NetIP) +"/" + $item.Subnet
    $SCVMMallSubnetVlanVlanID = $item.VLAN
    Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
        Param($SCVMMlogicalNetworkName,$SCVMMallSubnetVlanSubnet,$SCVMMallSubnetVlanVlanID,$SCVMMallHostGroupsName)
        Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
        Get-SCVMMServer -ComputerName localhost | Out-Null

        $SCVMMlogicalNetworkName,$SCVMMallSubnetVlanSubnet,$SCVMMallSubnetVlanVlanID,$SCVMMallHostGroupsName

        $SCVMMlogicalNetwork = New-SCLogicalNetwork -Name $SCVMMlogicalNetworkName -LogicalNetworkDefinitionIsolation $false -EnableNetworkVirtualization $false -UseGRE $false -IsPVLAN $false
        $SCVMMallHostGroups = @()
        $SCVMMallHostGroups += Get-SCVMHostGroup  -Name $SCVMMallHostGroupsName
        $SCVMMallSubnetVlan = @()
        $SCVMMallSubnetVlan += New-SCSubnetVLan -Subnet $SCVMMallSubnetVlanSubnet -VLanID $SCVMMallSubnetVlanVlanID

        New-SCLogicalNetworkDefinition -Name ($SCVMMlogicalNetworkName + "_0") -LogicalNetwork $SCVMMlogicalNetwork -VMHostGroup $SCVMMallHostGroups -SubnetVLan $SCVMMallSubnetVlan
        New-SCVMNetwork -Name $SCVMMlogicalNetworkName -IsolationType "NoIsolation" -LogicalNetwork $SCVMMlogicalNetwork

    } -Credential $domainCred -ArgumentList $SCVMMlogicalNetworkName,$SCVMMallSubnetVlanSubnet,$SCVMMallSubnetVlanVlanID,$SCVMMallHostGroupsName
}

#Action
$Action = "Add all Networks to all Switches, using the loop-in-loop"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null
    $portProfiles = Get-SCNativeUplinkPortProfile
  
    foreach($item in $portProfiles){
        $portProfile = Get-SCNativeUplinkPortProfile -Name ($item.Name)
        $portProfile.name
        $SCLogicalNetworkDefinitions = Get-SCLogicalNetworkDefinition
        foreach($obj in $SCLogicalNetworkDefinitions){
            Set-SCNativeUplinkPortProfile -NativeUplinkPortProfile $portProfile -AddLogicalNetworkDefinition $obj
        }
    }
} -Credential $domainCred

#Action
$Action = "Create all IP Pools"
Update-VIALog -Data "Action: $Action"
$return = foreach($Item in $NetworksData){
    $Data = [ordered]@{
    Name = $Item.Name;
    NetIP = $Item.NetIP;
    Gateway = $Item.Gateway;
    Subnet = $Item.Subnet;
    DNS = $Item.DNS;
    VLAN = $Item.vlan;
    VMMStart = $Item.VMMStart;
    VMMEnd = $Item.VMMEnd;
    }
    New-Object -TypeName psobject -Property $Data
}
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($Items)
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost | Out-Null

    Foreach($Item in $Items){
        # Get Logical Network 'FABRIC-MGMT'
        $logicalNetwork = Get-SCLogicalNetwork -Name $Item.Name

        # Get Logical Network Definition 'FABRIC-MGMT_0'
        $logicalNetworkDefinition = Get-SCLogicalNetworkDefinition -Name ($Item.Name + "_0")
        
        # Network Routes
        $allNetworkRoutes = @()

        # Gateways
        $allGateways = @()
        If($item.Gateway -eq 'NA'){}else{
            $allGateways += New-SCDefaultGateway -IPAddress $item.Gateway -Automatic
        }
        
        # DNS servers
        $allDnsServer = @()
        If($item.DNS -eq 'NA'){}else{
            $allDnsServer = @("$($item.DNS[0])", "$($item.DNS[1])")
        }

        # DNS suffixes
        $allDnsSuffixes = @()

        # WINS servers
        $allWinsServers = @()
        
        if(($item.VMMStart) -eq 'NA'){
        #New-SCStaticIPAddressPool -Name ($Item.Name + 'IP Pool') -LogicalNetworkDefinition $logicalNetworkDefinition -Subnet ($item.NetIP + '/' + $item.SubNet) -DefaultGateway $allGateways -DNSServer $allDnsServer -DNSSuffix "" -DNSSearchSuffix $allDnsSuffixes -NetworkRoute $allNetworkRoutes -RunAsynchronously
        }else{
        New-SCStaticIPAddressPool -Name ($Item.Name + 'IP Pool') -LogicalNetworkDefinition $logicalNetworkDefinition -Subnet ($item.NetIP + '/' + $item.SubNet) -IPAddressRangeStart $item.VMMStart -IPAddressRangeEnd $item.VMMEnd -DefaultGateway $allGateways -DNSServer $allDnsServer -DNSSuffix "" -DNSSearchSuffix $allDnsSuffixes -NetworkRoute $allNetworkRoutes -RunAsynchronously
        }
    }
} -Credential $domainCred -ArgumentList (,$return)
