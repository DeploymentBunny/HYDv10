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
$Action = "Create Hardware Profiles - Gen 1"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost

    #Create Hardware Profiles
    $SCVMMServerName = "FASCVM01"
    $SCVMMHardwareProfileSmallG1Name = "Small - Generation 1"
    $SCVMMHardwareProfileSmallG1Description = '2 x CPU, 2 GB of RAM'
    $SCVMMHardwareProfileMediumG1Name = "Medium - Generation 1"
    $SCVMMHardwareProfileMediumG1Description = '2 x CPU, 4 GB of RAM'
    $SCVMMHardwareProfileLargeG1Name = "Large - Generation 1"
    $SCVMMHardwareProfileLargeG1Description = '2 x CPU, 8 GB of RAM'
    $SCVMMHardwareProfileVeryLargeG1Name = "Very Large - Generation 1"
    $SCVMMHardwareProfileVeryLargeG1Description = '4 x CPU, 16 GB of RAM'
    $SCVMMHardwareProfileSmallG2Name = "Small - Generation 2"
    $SCVMMHardwareProfileSmallG2Description = '2 x CPU, 2 GB of RAM'
    $SCVMMHardwareProfileMediumG2Name = "Medium - Generation 2"
    $SCVMMHardwareProfileMediumG2Description = '2 x CPU, 4 GB of RAM'
    $SCVMMHardwareProfileLargeG2Name = "Large - Generation 2"
    $SCVMMHardwareProfileLargeG2Description = '2 x CPU, 8 GB of RAM'
    $SCVMMHardwareProfileVeryLargeG2Name = "Very Large - Generation 2"
    $SCVMMHardwareProfileVeryLargeG2Description = '4 x CPU, 16 GB of RAM'

    #Create Small Computer Hardware Profile
    $JobGroup = [guid]::NewGuid()
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 1 -LUN 0 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileSmallG1Name   `
    -Description $SCVMMHardwareProfileSmallG1Description   `
    -CPUCount 1   `
    -MemoryMB 2048   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 2048   `
    -DynamicMemoryMaximumMB 2048   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy"   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 1
    #Create Medium Computer Hardware Profile
    $JobGroup = [guid]::NewGuid() #HardwareProfile
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 1 -LUN 0 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileMediumG1Name   `
    -Description $SCVMMHardwareProfileMediumG1Description   `
    -CPUCount 2   `
    -MemoryMB 4096   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 4096   `
    -DynamicMemoryMaximumMB 4096   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy"   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 1

    #Create Large Computer Hardware Profile
    $JobGroup = [guid]::NewGuid() #HardwareProfile
    New-SCVirtualNetworkAdapter  -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter  -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive  -JobGroup $JobGroup -Bus 1 -LUN 0 
    New-SCHardwareProfile  -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType  | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileLargeG1Name   `
    -Description $SCVMMHardwareProfileLargeG1Description   `
    -CPUCount 2   `
    -MemoryMB 8192   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 8192   `
    -DynamicMemoryMaximumMB 8192   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy"   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 1

    #Create Extra Large Computer Hardware Profile
    $JobGroup = [guid]::NewGuid() #HardwareProfile
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 1 -LUN 0 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileVeryLargeG1Name   `
    -Description $SCVMMHardwareProfileVeryLargeG1Description   `
    -CPUCount 4   `
    -MemoryMB 16384   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 16384   `
    -DynamicMemoryMaximumMB 16384   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy"   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 1
} -Credential $domainCred

#Action
$Action = "Create Hardware Profiles - Gen 2"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost

    #Create Hardware Profiles
    $SCVMMServerName = "FASCVM01"
    $SCVMMHardwareProfileSmallG1Name = "Small - Generation 1"
    $SCVMMHardwareProfileSmallG1Description = '2 x CPU, 2 GB of RAM'
    $SCVMMHardwareProfileMediumG1Name = "Medium - Generation 1"
    $SCVMMHardwareProfileMediumG1Description = '2 x CPU, 4 GB of RAM'
    $SCVMMHardwareProfileLargeG1Name = "Large - Generation 1"
    $SCVMMHardwareProfileLargeG1Description = '2 x CPU, 8 GB of RAM'
    $SCVMMHardwareProfileVeryLargeG1Name = "Very Large - Generation 1"
    $SCVMMHardwareProfileVeryLargeG1Description = '4 x CPU, 16 GB of RAM'
    $SCVMMHardwareProfileSmallG2Name = "Small - Generation 2"
    $SCVMMHardwareProfileSmallG2Description = '2 x CPU, 2 GB of RAM'
    $SCVMMHardwareProfileMediumG2Name = "Medium - Generation 2"
    $SCVMMHardwareProfileMediumG2Description = '2 x CPU, 4 GB of RAM'
    $SCVMMHardwareProfileLargeG2Name = "Large - Generation 2"
    $SCVMMHardwareProfileLargeG2Description = '2 x CPU, 8 GB of RAM'
    $SCVMMHardwareProfileVeryLargeG2Name = "Very Large - Generation 2"
    $SCVMMHardwareProfileVeryLargeG2Description = '4 x CPU, 16 GB of RAM'

    #Create Small Computer Hardware Profile for UEFI
    $JobGroup = [guid]::NewGuid()
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 0 -LUN 1 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileSmallG2Name   `
    -Description $SCVMMHardwareProfileSmallG2Description   `
    -CPUCount 1   `
    -MemoryMB 2048   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 2048   `
    -DynamicMemoryMaximumMB 2048   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 2 -SecureBootEnabled $true
    #Create Medium Computer Hardware Profile
    $JobGroup = [guid]::NewGuid() #HardwareProfile
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 0 -LUN 1 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileMediumG2Name   `
    -Description $SCVMMHardwareProfileMediumG2Description   `
    -CPUCount 2   `
    -MemoryMB 4096   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 4096   `
    -DynamicMemoryMaximumMB 4096   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 2 -SecureBootEnabled $true

    #Create Large Computer Hardware Profile
    $JobGroup = [guid]::NewGuid() #HardwareProfile
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 0 -LUN 1 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileLargeG2Name   `
    -Description $SCVMMHardwareProfileLargeG2Description   `
    -CPUCount 2   `
    -MemoryMB 8192   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 8192   `
    -DynamicMemoryMaximumMB 8192   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 2 -SecureBootEnabled $true

    #Create Extra Large Computer Hardware Profile
    $JobGroup = [guid]::NewGuid() #HardwareProfile
    New-SCVirtualNetworkAdapter -JobGroup $JobGroup -MACAddress "00:00:00:00:00:00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Dynamic -IPv6AddressType Dynamic
    New-SCVirtualScsiAdapter -JobGroup $JobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
    New-SCVirtualDVDDrive -JobGroup $JobGroup -Bus 0 -LUN 1 
    New-SCHardwareProfile -JobGroup $JobGroup  `
    -CPUType (Get-SCCPUType | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"})  `
    -Name $SCVMMHardwareProfileVeryLargeG2Name   `
    -Description $SCVMMHardwareProfileVeryLargeG2Description   `
    -CPUCount 4   `
    -MemoryMB 16384   `
    -DynamicMemoryEnabled $true   `
    -DynamicMemoryMinimumMB 16384   `
    -DynamicMemoryMaximumMB 16384   `
    -DynamicMemoryBufferPercentage 20   `
    -MemoryWeight 5000   `
    -VirtualVideoAdapterEnabled $false   `
    -CPUExpectedUtilizationPercent 20   `
    -DiskIops 0   `
    -CPUMaximumPercent 100   `
    -CPUReserve 0   `
    -NumaIsolationRequired $false   `
    -NetworkUtilizationMbps 0   `
    -CPURelativeWeight 100   `
    -HighlyAvailable $false   `
    -DRProtectionRequired $false   `
    -NumLock $false   `
    -CPULimitFunctionality $false   `
    -CPULimitForMigration $true   `
    -CapabilityProfile (Get-SCCapabilityProfile | where {$_.Name -eq "Hyper-V"})   `
    -Generation 2 -SecureBootEnabled $true

} -Credential $domainCred


#Action
$Action = "Upload Custom VHDs"
Update-VIALog -Data "Action: $Action"
$Source = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx"
$Destination = "E:\ProgramData\Virtual Machine Manager Library Files\VHDs\WS2016-DCE_UEFI.vhdx"
Get-VM -Name $($ServerData.ComputerName) | Enable-VMIntegrationService -Name "Guest Service Interface"
Copy-VMFile -VM (Get-VM -Name $($ServerData.ComputerName)) -SourcePath $Source -DestinationPath $Destination -FileSource Host -CreateFullPath -Force

#Action
$Action = "Refresh SCLibrary"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Import-Module 'C:\Program Files\Microsoft System Center 2016\Virtual Machine Manager\bin\psModules\virtualmachinemanager'
    Get-SCVMMServer -ComputerName localhost
    Get-SCLibraryShare | Read-SCLibraryShare
} -Credential $domainCred



#### Custom Code ###


#-----------


#Create Windows Server 2012 R2 OS Profile
$AccountDescription = ($Settings.Fabric.DomainDefaults.ADUsers | Where-Object -Property UserName -EQ -Value SVC_SCVMM_AA).AccountDescription
$SCVMMGuestOSProfileFORWS2012R2Name = "OS Profile for Windows Server 2012 R2 in Fabric"
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName)  -Name $AccountDescription
$DomainJoinCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName)  -Name $AccountDescription
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName)  | where {$_.Name -eq "Windows Server 2012 R2 Standard"}
New-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName)    `
-Name $SCVMMGuestOSProfileFORWS2012R2Name    `
-Description $SCVMMGuestOSProfileFORWS2012R2Name    `
-ComputerName "*"    `
-TimeZone 110    `
-LocalAdministratorCredential $LocalAdministratorCredential     `
-FullName $env:USERDOMAIN    `
-OrganizationName $env:USERDOMAIN    `
-Domain $env:USERDNSDOMAIN    `
-DomainJoinCredential $DomainJoinCredential    `
-AnswerFile $null    `
-OperatingSystem $OperatingSystem    `
-Owner "" 

#Copy the Fabric VHDs
$SCVMMDefaultLib = Get-SCLibraryShare
$SCVMMDefaultLibPath =$SCVMMDefaultLib.Path
Copy-Item -Path '\\fadepl01\ApplicationRoot\VHD\WS2012R2G1Fabric.vhdx' -Destination ($SCVMMDefaultLibPath + "\VHDs")
Copy-Item -Path '\\fadepl01\ApplicationRoot\VHD\WS2012R2G2Fabric.vhdx' -Destination ($SCVMMDefaultLibPath + "\VHDs")
Get-SCLibraryShare | Read-SCLibraryShare

#Set prop on imported disks
$libraryObject = Get-SCVirtualHardDisk -Name "WS2012R2G1Fabric.vhdx"
$os = Get-SCOperatingSystem | where {$_.Name -eq "Windows Server 2012 R2 Standard"}
Set-SCVirtualHardDisk -VirtualHardDisk $libraryObject -OperatingSystem $os -VirtualizationPlatform "HyperV" -Name "WS2012R2G1Fabric.vhdx" -Description "" -Release "" -FamilyName ""

#Set prop on imported disks
$libraryObject = Get-SCVirtualHardDisk -Name "WS2012R2G2Fabric.vhdx"
$os = Get-SCOperatingSystem | where {$_.Name -eq "Windows Server 2012 R2 Standard"}
Set-SCVirtualHardDisk -VirtualHardDisk $libraryObject -OperatingSystem $os -VirtualizationPlatform "HyperV" -Name "WS2012R2G2Fabric.vhdx" -Description "" -Release "" -FamilyName ""

#Create VM templates for Fabric G1

#Create VM template for Windows Server 2012 R2 Small G1
$SCVMMVMTemplateForWS2012R2SmallG1Name = "Windows Server 2012 R2 G1 - Small"
$SCVMMVMTemplateForWS2012R2SmallG1Disk = "WS2012R2G1Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2SmallG1HWProfile = "Small - Generation 1"
$SCVMMVMTemplateForWS2012R2SmallG1OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2SmallG1OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG1Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -IDE -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG1HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG1OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG1OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2SmallG1Name -Generation 1 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 

#Create VM template for Windows Server 2012 R2 Medium G1
$SCVMMVMTemplateForWS2012R2MediumG1Name = "Windows Server 2012 R2 G1 - Medium"
$SCVMMVMTemplateForWS2012R2MediumG1Disk = "WS2012R2G1Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2MediumG1HWProfile = "Medium - Generation 1"
$SCVMMVMTemplateForWS2012R2MediumG1OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2MediumG1OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG1Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -IDE -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG1HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG1OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG1OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2MediumG1Name -Generation 1 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 

#Create VM template for Windows Server 2012 R2 Large G1
$SCVMMVMTemplateForWS2012R2LargeG1Name = "Windows Server 2012 R2 G1 - Large"
$SCVMMVMTemplateForWS2012R2LargeG1Disk = "WS2012R2G1Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2LargeG1HWProfile = "Large - Generation 1"
$SCVMMVMTemplateForWS2012R2LargeG1OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2LargeG1OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG1Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -IDE -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG1HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG1OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG1OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2LargeG1Name -Generation 1 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 

#Create VM template for Windows Server 2012 R2 Very Large G1
$SCVMMVMTemplateForWS2012R2VeryLargeG1Name = "Windows Server 2012 R2 G1 - Very Large"
$SCVMMVMTemplateForWS2012R2VeryLargeG1Disk = "WS2012R2G1Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2VeryLargeG1HWProfile = "Very Large - Generation 1"
$SCVMMVMTemplateForWS2012R2VeryLargeG1OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2VeryLargeG1OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG1Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -IDE -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG1HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG1OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG1OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2VeryLargeG1Name -Generation 1 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 

#Create VM templates for Fabric G2

#Create VM template for Windows Server 2012 R2 Small G2
$SCVMMVMTemplateForWS2012R2SmallG2Name = "Windows Server 2012 R2 G2 - Small"
$SCVMMVMTemplateForWS2012R2SmallG2Disk = "WS2012R2G2Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2SmallG2HWProfile = "Small - Generation 2"
$SCVMMVMTemplateForWS2012R2SmallG2OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2SmallG2OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG2Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 2 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG2HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG2OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2SmallG2OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2SmallG2Name -Generation 2 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 
$template | set-scvmtemplate -FirstBootDevice “SCSI,0,0”

#Create VM template for Windows Server 2012 R2 Medium G2
$SCVMMVMTemplateForWS2012R2MediumG2Name = "Windows Server 2012 R2 G2 - Medium"
$SCVMMVMTemplateForWS2012R2MediumG2Disk = "WS2012R2G2Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2MediumG2HWProfile = "Medium - Generation 2"
$SCVMMVMTemplateForWS2012R2MediumG2OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2MediumG2OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG2Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 2 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG2HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG2OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2MediumG2OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2MediumG2Name -Generation 2 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 
$template | set-scvmtemplate -FirstBootDevice “SCSI,0,0”

#Create VM template for Windows Server 2012 R2 Large G2
$SCVMMVMTemplateForWS2012R2LargeG2Name = "Windows Server 2012 R2 G2 - Large"
$SCVMMVMTemplateForWS2012R2LargeG2Disk = "WS2012R2G2Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2LargeG2HWProfile = "Large - Generation 2"
$SCVMMVMTemplateForWS2012R2LargeG2OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2LargeG2OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG2Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 2 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG2HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG2OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2LargeG2OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2LargeG2Name -Generation 2 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 
$template | set-scvmtemplate -FirstBootDevice “SCSI,0,0”

#Create VM template for Windows Server 2012 R2 Very Large G2
$SCVMMVMTemplateForWS2012R2VeryLargeG2Name = "Windows Server 2012 R2 G2 - Very Large"
$SCVMMVMTemplateForWS2012R2VeryLargeG2Disk = "WS2012R2G2Fabric.vhdx"
$SCVMMVMTemplateForWS2012R2VeryLargeG2HWProfile = "Very Large - Generation 2"
$SCVMMVMTemplateForWS2012R2VeryLargeG2OSProfile = "OS Profile for Windows Server 2012 R2 in Fabric"
$SCVMMVMTemplateForWS2012R2VeryLargeG2OSVersion = "Windows Server 2012 R2 Standard"

$JobGroup = [guid]::NewGuid() #HardwareProfile
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG2Disk}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 0 -JobGroup $JobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType BootAndSystem
$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq "Blank Disk - Large.vhdx"}
New-SCVirtualDiskDrive -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -SCSI -Bus 0 -LUN 2 -JobGroup $JobGroup -SharedStorage $false -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -VolumeType None 
$HardwareProfile = Get-SCHardwareProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG2HWProfile}
$GuestOSProfile = Get-SCGuestOSProfile -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG2OSProfile}
$LocalAdministratorCredential = Get-SCRunAsAccount -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) -Name "SCVMM Administrator"
$OperatingSystem = Get-SCOperatingSystem -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMVMTemplateForWS2012R2VeryLargeG2OSVersion}
$template = New-SCVMTemplate -Name $SCVMMVMTemplateForWS2012R2VeryLargeG2Name -Generation 2 -HardwareProfile $HardwareProfile -GuestOSProfile $GuestOSProfile -JobGroup $JobGroup -ComputerName "*" -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential  -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -AnswerFile $null -OperatingSystem $OperatingSystem 
$template | set-scvmtemplate -FirstBootDevice “SCSI,0,0”

#Create Physical Profile
$SCVMMComputeDisk = "WS2012R2G1Fabric.vhdx"
$SCVMMComputeProfileName = "Compute - Dell"
$SCVMMComputeProfileTag = "Compute-Dell-WS2012R2"
$SCVMMComputeProfileLocalAdminPW = "Fabric4Ever!"
$SecurePassword = ConvertTo-SecureString $SCVMMComputeProfileLocalAdminPW -AsPlainText -Force
$AdminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Administrator", $SecurePassword

$VHD = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMComputeDisk}
$RunAsAccount = Get-SCRunAsAccount -Name "Admin Account for SCVMM"
$NicProfilesArray = @()
$LogicalSwitch = Get-SCLogicalSwitch -Name "UplinkSwitch"
$UplinkPortProfileSet = Get-SCUplinkPortProfileSet -Name "UpLinkPortProfileSet"
$PhysicalComputerNetworkAdapterProfile = New-SCPhysicalComputerNetworkAdapterProfile -SetAsPhysicalNetworkAdapter -LogicalSwitch $LogicalSwitch -UplinkPortProfileSet $UplinkPortProfileSet
$NicProfilesArray += $PhysicalComputerNetworkAdapterProfile

$PortClassification = Get-SCPortClassification -Name "Host management"
$LogicalSwitch = Get-SCLogicalSwitch -Name "UplinkSwitch"
$VMNetwork = Get-SCVMNetwork -Name "Fabric-MGMT"
$NicProfile1 = New-SCPhysicalComputerNetworkAdapterProfile -SetAsManagementNIC -SetAsVirtualNetworkAdapter -UseStaticIPForIPConfiguration -TransientManagementNetworkAdapter $PhysicalComputerNetworkAdapterProfile -LogicalSwitch $LogicalSwitch -PortClassification $PortClassification -VMNetwork $VMNetwork
$NicProfilesArray += $NicProfile1

$Tags = @($SCVMMComputeProfileTag)
New-SCPhysicalComputerProfile -Name $SCVMMComputeProfileName -Description "" -DiskConfiguration "MBR=1:PRIMARY:QUICK:4:FALSE:OSBootDisk::0:BOOTPARTITION;" -Domain $env:USERDNSDOMAIN -TimeZone 110 -RunAsynchronously -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -ProductKey "" -VMPaths "" -UseAsVMHost -VirtualHardDisk $VHD -BypassVHDConversion $false -DomainJoinRunAsAccount $RunAsAccount -LocalAdministratorCredential $AdminCredentials -PhysicalComputerNetworkAdapterProfile $NicProfilesArray -DriverMatchingTag $Tags

#Create Physical Profile
$SCVMMComputeDisk = "WS2012R2G1Fabric.vhdx"
$SCVMMComputeProfileName = "Compute - HP"
$SCVMMComputeProfileTag = "Compute-HP-WS2012R2"
$SCVMMComputeProfileLocalAdminPW = "Fabric4Ever!"
$SecurePassword = ConvertTo-SecureString $SCVMMComputeProfileLocalAdminPW -AsPlainText -Force
$AdminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Administrator", $SecurePassword

$VHD = Get-SCVirtualHardDisk -VMMServer (Get-SCVMMServer -ComputerName $SCVMMServerName) | where {$_.Name -eq $SCVMMComputeDisk}
$RunAsAccount = Get-SCRunAsAccount -Name "Admin Account for SCVMM"
$NicProfilesArray = @()
$LogicalSwitch = Get-SCLogicalSwitch -Name "UplinkSwitch"
$UplinkPortProfileSet = Get-SCUplinkPortProfileSet -Name "UpLinkPortProfileSet"
$PhysicalComputerNetworkAdapterProfile = New-SCPhysicalComputerNetworkAdapterProfile -SetAsPhysicalNetworkAdapter -LogicalSwitch $LogicalSwitch -UplinkPortProfileSet $UplinkPortProfileSet
$NicProfilesArray += $PhysicalComputerNetworkAdapterProfile

$PortClassification = Get-SCPortClassification -Name "Host management"
$LogicalSwitch = Get-SCLogicalSwitch -Name "UplinkSwitch"
$VMNetwork = Get-SCVMNetwork -Name "Fabric-MGMT"
$NicProfile1 = New-SCPhysicalComputerNetworkAdapterProfile -SetAsManagementNIC -SetAsVirtualNetworkAdapter -UseStaticIPForIPConfiguration -TransientManagementNetworkAdapter $PhysicalComputerNetworkAdapterProfile -LogicalSwitch $LogicalSwitch -PortClassification $PortClassification -VMNetwork $VMNetwork
$NicProfilesArray += $NicProfile1

$Tags = @($SCVMMComputeProfileTag)
New-SCPhysicalComputerProfile -Name $SCVMMComputeProfileName -Description "" -DiskConfiguration "MBR=1:PRIMARY:QUICK:4:FALSE:OSBootDisk::0:BOOTPARTITION;" -Domain $env:USERDNSDOMAIN -TimeZone 110 -RunAsynchronously -FullName $env:USERDOMAIN -OrganizationName $env:USERDOMAIN -ProductKey "" -VMPaths "" -UseAsVMHost -VirtualHardDisk $VHD -BypassVHDConversion $false -DomainJoinRunAsAccount $RunAsAccount -LocalAdministratorCredential $AdminCredentials -PhysicalComputerNetworkAdapterProfile $NicProfilesArray -DriverMatchingTag $Tags

BREAK

#Import drivers to LIB
$SCVMMDefaultLib = Get-SCLibraryShare
$SCVMMDefaultLibPath =$SCVMMDefaultLib.Path
New-Item -Path "$SCVMMDefaultLibPath\Drivers" -ItemType Directory -Force
Copy-item -Path \\fadepl01\ApplicationRoot\Install-Drivers\Source\* -Destination "$SCVMMDefaultLibPath\Drivers" -Recurse -force
Get-SCLibraryShare | Read-SCLibraryShare

#Tag WinPEx64
$Tag = "WinPEx64"
$Source = $SCVMMDefaultLibPath + "\Drivers\WinPE"
$Inffiles = Get-ChildItem -Path $source -filter *.inf -Recurse
foreach ($Inffile in $Inffiles)
{
    $DriverFile = $Inffile.FullName
    $DriverPackage = Get-SCDriverPackage | Where-Object {$_.SharePath -eq $DriverFile}
    $DriverPackage.SharePath
    Set-SCDriverPackage -DriverPackage $DriverPackage -Tag $Tag -RunAsynchronously
}

#Tag Compute-Dell-WS2012R2
$Tag = "Dell-PowerEdge-WS2012R2"
$Source = $SCVMMDefaultLibPath + "\Drivers\Dell-PowerEdge-WS2012R2"
$Inffiles = Get-ChildItem -Path $source -filter *.inf -Recurse
foreach ($Inffile in $Inffiles)
{
    $DriverFile = $Inffile.FullName
    $DriverPackage = Get-SCDriverPackage | Where-Object {$_.SharePath -eq $DriverFile}
    $DriverPackage.SharePath
    Set-SCDriverPackage -DriverPackage $DriverPackage -Tag $Tag -RunAsynchronously
}

#Tag Compute-HP-WS2012R2
$Tag = "HP-Proliant-WS2012R2"
$Source = $SCVMMDefaultLibPath + "\Drivers\HP-Proliant-WS2012R2"
$Inffiles = Get-ChildItem -Path $source -filter *.inf -Recurse
foreach ($Inffile in $Inffiles)
{
    $DriverFile = $Inffile.FullName
    $DriverPackage = Get-SCDriverPackage | Where-Object {$_.SharePath -eq $DriverFile}
    $DriverPackage.SharePath
    Set-SCDriverPackage -DriverPackage $DriverPackage -Tag $Tag -RunAsynchronously
}

#Update WinPE
$mountdir = "e:\mount" 
$winpeimage = '\\fadepl01\REMINST\DCMgr\Boot\Windows\Images\Boot.wim' 
$winpeimagetemp = $winpeimage + ".tmp" 
mkdir $mountdir -ErrorAction SilentlyContinue
copy $winpeimage $winpeimagetemp 
dism /mount-wim /wimfile:$winpeimagetemp /index:1 /mountdir:$mountdir 
$drivers = get-scdriverpackage | where { $_.tags -match "WinPEx64" } 
foreach ($driver in $drivers) 
{
    $path = $driver.sharepath 
    dism /image:$mountdir /add-driver /driver:$path 
} 
Dism /Unmount-Wim /MountDir:$mountdir /Commit 
publish-scwindowspe -path $winpeimagetemp 
del $winpeimagetemp


