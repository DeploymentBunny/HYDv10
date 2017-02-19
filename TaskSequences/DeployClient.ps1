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
    [String]
    $Computer = $Computer,

    [parameter(Position=6,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DomainName,

    [parameter(Position=7,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $FinishAction,

    [parameter(Position=8,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $VMSwitchName = 'NA',

    [parameter(Position=9,mandatory=$False)]
    [Switch]
    $KeepMountedMedia
)

##############
#Init

#Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Read data from Bootstrap XML
Write-Verbose "Reading $BootstrapFile"
[xml]$Bootstrap = Get-Content $BootstrapFile -ErrorAction Stop

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop

#Set Values
$ComputerName = $Computer
$CustomerData = $Settings.settings.Customers.Customer
$CommonSettingData = $Settings.settings.CommonSettings.CommonSetting
$ProductKeysData = $Settings.settings.ProductKeys.ProductKey
$NetworksData = $Settings.settings.Networks.Network
$DomainData = $Settings.settings.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ComputerData = $Settings.settings.Computers.Computer | Where-Object -Property Name -EQ -Value $ComputerName

$NIC01 = $ComputerData.Networkadapters.Networkadapter | Where-Object -Property Name -EQ -Value NIC01
$NIC01RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC01.ConnectedToNetwork

$MountFolder = "C:\MountVHD"
$AdminPassword = $CommonSettingData.LocalPassword
$DomainInstaller = $DomainData.DomainAdmin
$DomainName = $DomainData.DomainAdminDomain
$DNSDomain = $DomainData.DNSDomain
$DomainAdminPassword = $DomainData.DomainAdminPassword
$VMMemory = [int]$ComputerData.Memory * 1024 * 1024
if($VMSwitchName -eq 'NA'){$VMSwitchName = $CommonSettingData.VMSwitchName}
$VIASetupCompletecmdCommand = "cmd.exe /c PowerShell.exe -Command New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name OSDeployment -Value Done -PropertyType String"
$SetupRoot = "C:\Setup"

If($($ComputerData.DomainJoined) -eq 'true'){$DomainOrWorkGroup = 'Domain'}else{$DomainOrWorkGroup = 'Workgroup'}

if($FinishAction -eq $Null){
    $FinishAction = $ComputerData.Finishaction
}

#Verbose output
Write-Verbose "ComputerName: $($ComputerData.ComputerName)"
Write-Verbose "Roles: $Roles"
Write-Verbose "Joined to: $DomainOrWorkGroup"
Write-Verbose "Datadisks: $(($ComputerData.DataDisks.DataDisk | Where-Object Active -NE False).Name)"

#Create credentials
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($ComputerData.ComputerName)\Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)
if($DomainOrWorkGroup -eq 'Workgroup'){$DefaultCred = $localCred}
if($DomainOrWorkGroup -eq 'Domain'){$DefaultCred = $domainCred}

### End Init ###

If ((Test-VIAVMExists -VMname $($ComputerData.ComputerName)) -eq $true){Write-Warning "$($ComputerData.ComputerName) already exist";Exit}
Write-Verbose "Creating $($ComputerData.ComputerName)"
$VM = New-VIAVM -VMName $($ComputerData.ComputerName) -VMMem $VMMemory -VMvCPU 2 -VMLocation $VMLocation -VHDFile $VHDImage -DiskMode Diff -VMSwitchName $VMSwitchName -VMGeneration 2 -Verbose

#Enable Device Naming
$Action = "Enable Device Naming"
Write-Verbose "$Action"
Enable-VIAVMDeviceNaming -VMName $($ComputerData.ComputerName)

if($DomainOrWorkGroup -eq 'Workgroup'){
    $VIAUnattendXML = New-VIAUnattendXMLClient -Computername $($ComputerData.ComputerName) -OSDAdapter0IPAddressList $NIC01.IPAddress -DomainOrWorkGroup Workgroup -ProtectYourPC 3 -OSDAdapter0Gateways $NIC01RelatedData.Gateway -OSDAdapter0DNS1 $NIC01RelatedData.DNS[0] -OSDAdapter0DNS2 $NIC01RelatedData.DNS[1] -OSDAdapter0SubnetMaskPrefix $NIC01RelatedData.SubNet -OrgName $CustomerData.Name -Fullname $CustomerData.Name -TimeZoneName $CommonSettingData.TimeZoneName
}

if($DomainOrWorkGroup -eq 'Domain'){
    $VIAUnattendXML = New-VIAUnattendXMLClient -Computername $($ComputerData.ComputerName) -OSDAdapter0IPAddressList $NIC01.IPAddress -DomainOrWorkGroup Domain -ProtectYourPC 3 -Verbose -OSDAdapter0Gateways $NIC01RelatedData.Gateway -OSDAdapter0DNS1 $NIC01RelatedData.DNS[0] -OSDAdapter0DNS2 $NIC01RelatedData.DNS[1] -OSDAdapter0SubnetMaskPrefix $NIC01RelatedData.SubNet -OrgName $CustomerData.Name -Fullname $CustomerData.Name -TimeZoneName $CommonSettingData.TimeZoneName -DNSDomain $DomainData.DNSDomain -DomainAdmin $DomainData.DomainAdmin -DomainAdminPassword $DomainData.DomainAdminPassword -DomainAdminDomain $DomainData.DomainAdminDomain
}

$VIASetupCompletecmd = New-VIASetupCompleteCMD -Command $VIASetupCompletecmdCommand -Verbose
$VHDFile = (Get-VMHardDiskDrive -VMName $($ComputerData.ComputerName)).Path
Mount-VIAVHDInFolder -VHDfile $VHDFile -VHDClass UEFI -MountFolder $MountFolder 
New-Item -Path "$MountFolder\Windows\Panther" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Windows\Setup" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Windows\Setup\Scripts" -ItemType Directory -Force | Out-Null
Copy-Item -Path $VIAUnattendXML.FullName -Destination "$MountFolder\Windows\Panther\$($VIAUnattendXML.Name)" -Force
Copy-Item -Path $VIASetupCompletecmd.FullName -Destination "$MountFolder\Windows\Setup\Scripts\$($VIASetupCompletecmd.Name)" -Force
Copy-Item -Path $SetupRoot\functions -Destination $MountFolder\Setup\Functions -Container -Recurse
Copy-Item -Path $SetupRoot\HYDV10 -Destination $MountFolder\Setup\HYDV10 -Container -Recurse
Dismount-VIAVHDInFolder -VHDfile $VHDFile -MountFolder $MountFolder
#Remove-Item -Path $VIAUnattendXML.FullName
#Remove-Item -Path $VIASetupCompletecmd.FullName

#Set VLANid for NIC01
$ConnectedtoNetwork = $NetworksData | Where-Object -Property id -EQ -Value $NIC01RelatedData.id
if($ConnectedtoNetwork.VLAN -ne '0'){
    Write-Verbose "Setting VLAN $($ConnectedtoNetwork.VLAN)"
    Set-VMNetworkAdapterVlan -VMName $($ComputerData.ComputerName) -VlanId $ConnectedtoNetwork.VLAN -Access
}


#Deploy VM
$Action = "Deploy VM"
Write-Verbose "$Action"
Wait-VIAVMStart -VMname $($ComputerData.ComputerName) -Credentials $localCred
Wait-VIAVMDeployment -VMname $($ComputerData.ComputerName)
Wait-VIAServiceToRun -VMname $($ComputerData.ComputerName) -Credentials $localCred
#Deploy VM end

##############

#ShutDown 
Stop-VM -Name $($ComputerData.ComputerName)

#Action
$Action = "Done"
Write-Verbose "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."
