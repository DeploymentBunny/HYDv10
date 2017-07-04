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
$ServerName = $Server
$CustomerData = $Settings.settings.Customers.Customer
$CommonSettingData = $Settings.settings.CommonSettings.CommonSetting
$ProductKeysData = $Settings.settings.ProductKeys.ProductKey
$NetworksData = $Settings.settings.Networks.Network
$DomainData = $Settings.settings.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.settings.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName

$NIC01 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property Name -EQ -Value NIC01
$NIC01RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC01.ConnectedToNetwork

$MountFolder = "C:\MountVHD"
$AdminPassword = $CommonSettingData.LocalPassword
$DomainInstaller = $DomainData.DomainAdmin
$DomainName = $DomainData.DomainAdminDomain
$DNSDomain = $DomainData.DNSDomain
$DomainAdminPassword = $DomainData.DomainAdminPassword
$VMMemory = [int]$ServerData.BuildMemory * 1024 * 1024
if($VMSwitchName -eq 'NA'){$VMSwitchName = $CommonSettingData.VMSwitchName}
$VIASetupCompletecmdCommand = "cmd.exe /c PowerShell.exe -Command New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name OSDeployment -Value Done -PropertyType String"
$SetupRoot = "C:\Setup"

If($($ServerData.DomainJoined) -eq 'true'){$DomainOrWorkGroup = 'Domain'}else{$DomainOrWorkGroup = 'Workgroup'}

if($Roles -eq $Null){
    foreach($Role in $ServerData.Roles.Role){
        $RoleConfig = $Settings.settings.Roles.Role | Where-Object Active -EQ $true | Where-Object id -EQ $Role.RoleUUID
        [array]$Roles += $RoleConfig.name
    }
}

if($FinishAction -eq $Null){
    $FinishAction = $ServerData.Finishaction
}

#Verbose output
Write-Verbose "ServerName: $($ServerData.ComputerName)"
Write-Verbose "VMName: $($ServerData.VMname)"
Write-Verbose "Roles: $Roles"
Write-Verbose "Joined to: $DomainOrWorkGroup"
Write-Verbose "Datadisks: $(($ServerData.DataDisks.DataDisk | Where-Object Active -NE False).Name)"

#Create credentials
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($ServerData.ComputerName)\Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force)
if($DomainOrWorkGroup -eq 'Workgroup'){$DefaultCred = $localCred}
if($DomainOrWorkGroup -eq 'Domain'){$DefaultCred = $domainCred}

### End Init ###

If ((Test-VIAVMExists -VMname $($ServerData.VMName)) -eq $true){Write-Warning "$($ServerData.VMName) already exist";Exit}
Write-Verbose "Creating $($ServerData.VMName)"
$VM = New-VIAVM -VMName $($ServerData.VMName) -VMMem $VMMemory -VMvCPU 2 -VMLocation $VMLocation -VHDFile $VHDImage -DiskMode Diff -VMSwitchName $VMSwitchName -VMGeneration 2 -Verbose

#Enable Device Naming
$Action = "Enable Device Naming"
Write-Verbose "$Action"
Enable-VIAVMDeviceNaming -VMName $($ServerData.VMName)

if($DomainOrWorkGroup -eq 'Workgroup'){
    $VIAUnattendXML = New-VIAUnattendXML -Computername $($ServerData.ComputerName) -OSDAdapter0IPAddressList $NIC01.IPAddress -DomainOrWorkGroup Workgroup -ProtectYourPC 3 -OSDAdapter0Gateways $NIC01RelatedData.Gateway -OSDAdapter0DNS1 $NIC01RelatedData.DNS[0] -OSDAdapter0DNS2 $NIC01RelatedData.DNS[1] -OSDAdapter0SubnetMaskPrefix $NIC01RelatedData.SubNet -OrgName $CustomerData.Name -Fullname $CustomerData.Name -TimeZoneName $CommonSettingData.TimeZoneName -AdminPassword $AdminPassword
}

if($DomainOrWorkGroup -eq 'Domain'){
    $VIAUnattendXML = New-VIAUnattendXML -Computername $($ServerData.ComputerName) -OSDAdapter0IPAddressList $NIC01.IPAddress -DomainOrWorkGroup Domain -ProtectYourPC 3 -Verbose -OSDAdapter0Gateways $NIC01RelatedData.Gateway -OSDAdapter0DNS1 $NIC01RelatedData.DNS[0] -OSDAdapter0DNS2 $NIC01RelatedData.DNS[1] -OSDAdapter0SubnetMaskPrefix $NIC01RelatedData.SubNet -OrgName $CustomerData.Name -Fullname $CustomerData.Name -TimeZoneName $CommonSettingData.TimeZoneName -DNSDomain $DomainData.DNSDomain -DomainAdmin $DomainData.DomainAdmin -DomainAdminPassword $DomainAdminPassword -DomainAdminDomain $DomainData.DomainAdminDomain -MachineObjectOU $ServerData.MachineObjectOU -AdminPassword $AdminPassword
}

$VIASetupCompletecmd = New-VIASetupCompleteCMD -Command $VIASetupCompletecmdCommand -Verbose
$VHDFile = (Get-VMHardDiskDrive -VMName $($ServerData.VMName)).Path
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
Remove-Item -Path $VIASetupCompletecmd.FullName

#Set VLANid for NIC01
$ConnectedtoNetwork = $NetworksData | Where-Object -Property id -EQ -Value $NIC01RelatedData.id
if($ConnectedtoNetwork.VLAN -ne '0'){
    Write-Verbose "Setting VLAN $($ConnectedtoNetwork.VLAN)"
    Set-VMNetworkAdapterVlan -VMName $($ServerData.VMName) -VlanId $ConnectedtoNetwork.VLAN -Access
}

#Deploy VM
$Action = "Deploy VM"
Write-Verbose "$Action"
Wait-VIAVMStart -VMname $($ServerData.VMName) -Credentials $localCred
Wait-VIAVMDeployment -VMname $($ServerData.VMName)
Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $localCred

#Wait just to be sure it will work to logon
Start-Sleep -Seconds 45

#Action
$Action = "Enable Remote Desktop"
Write-Verbose "Action: $Action"
try{Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /AR 0} -ErrorAction Stop -Credential $DefaultCred}catch{Write-Warning "Woops..."}

#Action
$Action = "Set Remote Destop Security"
Write-Verbose "Action: $Action"
try{Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /CS 0} -ErrorAction Stop -Credential $DefaultCred}catch{Write-Warning "Woops..."}

#Rename Default NetworkAdapter
$Action = "Rename Default NetworkAdapter"
Write-Verbose "$Action"
Rename-VMNetworkAdapter -VMName $($ServerData.VMName) -NewName $NIC01.Name 
$NewNicName = $($NIC01.Name)
$RemoteCommand = {
    Import-Module C:\Setup\Functions\VIANicModule.psm1
    Rename-VIANetAdapterUsingDeviceNaming -VMDeviceName $Using:NewNicName
}
Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock $RemoteCommand -Credential $DefaultCred -HideComputerName -Verbose -ErrorAction Stop

#Add rest of the Network Adapters
$Action = "Add rest of the Network Adapters"
Write-Verbose "$Action"
$Nics = $ServerData.Networkadapters.Networkadapter | Where-Object -Property Active -EQ -Value True | Where-Object -Property Name -NE -Value NIC01
foreach($Item in $Nics){
    $ConnectedtoNetwork = $NetworksData | Where-Object -Property id -EQ -Value $item.ConnectedToNetwork
    $VMSwitchName = ($Bootstrap.BootStrap.Networks.Network | Where-Object -Property Name -EQ -Value $ConnectedtoNetwork.Name).VMSwitchName
    Add-VMNetworkAdapter -VMName $($ServerData.VMName) -SwitchName $VMSwitchName -Name $Item.Name -DeviceNaming On
    if(!($ConnectedtoNetwork.VLAN -eq 'NA')){
        Set-VMNetworkAdapterVlan -VMName $($ServerData.VMName) -VMNetworkAdapterName $Item.Name -VlanId $ConnectedtoNetwork.VLAN -Access
    }
}

#Rename the rest of the NetworkAdapters
$Action = "Rename the rest of the NetworkAdapters"
Write-Verbose "$Action"
$Nics = $ServerData.Networkadapters.Networkadapter | Where-Object -Property Active -EQ -Value True | Where-Object -Property Name -NE -Value NIC01
foreach($Item in $Nics){
    $NewNicName = $($Item.Name)
    $RemoteCommand = {
        Import-Module C:\Setup\Functions\VIANicModule.psm1
        Rename-VIANetAdapterUsingDeviceNaming -VMDeviceName $Using:NewNicName
    }
    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock $RemoteCommand -Credential $DefaultCred -HideComputerName -Verbose
}

#Action
$Action = "Add Datadisks"
Write-Verbose "$Action"
foreach($obj in $ServerData.DataDisks.DataDisk){
    If($obj.DiskSize -ne 'NA'){
     C:\Setup\HYDv10\Scripts\New-VIADataDisk.ps1 -VMName $($ServerData.VMName) -DiskLabel $obj.Name -DiskSize $obj.DiskSize
    }
}

#Action
$Action = "Partion and Format DataDisk(s)"
Write-Verbose "Action: $Action"
foreach ($obj in ($ServerData.DataDisks.DataDisk | Where-Object Active -EQ $true)){
    $RemoteCommand = {
        Import-Module C:\Setup\Functions\VIAStorageModule.psm1
        Initialize-VIADataDisk -DiskNumber $Using:obj.DiskNumber -FileSystem $Using:obj.FileSystem -PartitionType $Using:obj.PartitionType -FileSystemLabel $Using:obj.Name
    }
    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock $RemoteCommand -Credential $DefaultCred -HideComputerName -Verbose
}

#Action
$Action = "Mount Media ISO"
if($MediaISO -ne 'NA'){
    Update-VIALog -Data "Action: $Action"
    Set-VMDvdDrive -VMName $($ServerData.VMName) -Path $MediaISO
}

#TBA
#Configure Nic Teams
$Teams = $ServerData.NetworkTeams.Networkteam | Where-Object -Property Active -EQ -Value $True
if(((($Teams.Name).count) -ge '1') -eq $true){
    foreach($Team in $Teams){
        $Team
    }
}

#Deploy VM end

##############

#Begin Custom Actions

#Configure global settings for all servers in the fabric
$Action = "Remove-WindowsFeature -Name FS-SMB1 -Norestart"
Update-VIALog -Data "Action: $Action"
$ScriptBlock = {Remove-WindowsFeature -Name FS-SMB1}
Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $DefaultCred

Update-VIALog -Data "Restart $($ServerData.VMName)"
Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $DefaultCred
Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred

#Configure global settings for all servers in the fabric
$Action = "Start-SMPerformanceCollector -CollectorName 'Server Manager Performance Monitor'"
Update-VIALog -Data "Action: $Action"
$ScriptBlock = {Start-SMPerformanceCollector -CollectorName 'Server Manager Performance Monitor'}
Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $DefaultCred

#Configure global settings for all servers in the fabric
$Action = "Get-Service -Name MapsBroker | Set-Service -StartupType Disabled"
Update-VIALog -Data "Action: $Action"
$ScriptBlock = {Get-Service -Name MapsBroker | Set-Service -StartupType Disabled}
Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $DefaultCred

#Configure global settings for all servers in the fabric
$Action = "Disable Show Welcome Tile for all users"
Update-VIALog -Data "Action: $Action"
$ScriptBlock = {
    $XMLBlock = @(
'<?xml version="1.0" encoding="utf-8"?>
  <configuration>
   <configSections>
    <sectionGroup name="userSettings" type="System.Configuration.UserSettingsGroup, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089">
    <section name="Microsoft.Windows.ServerManager.Common.Properties.Settings" type="System.Configuration.ClientSettingsSection, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" allowExeDefinition="MachineToLocalUser" requirePermission="false" />
    </sectionGroup>
   </configSections>
   <userSettings>
    <Microsoft.Windows.ServerManager.Common.Properties.Settings>
     <setting name="WelcomeTileVisibility" serializeAs="String">
      <value>Collapsed</value>
     </setting>
    </Microsoft.Windows.ServerManager.Common.Properties.Settings>
   </userSettings>
  </configuration>'
  )
    $XMLBlock | Out-File -FilePath C:\Windows\System32\ServerManager.exe.config -Encoding ascii -Force
    }
Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $DefaultCred

#Install Applications (Pre Roles and Features)
foreach($Role in $Roles){
    #Action
    $Action = "Install Applications (Pre Roles and Features)"
    Update-VIALog -Data "Action: $Action - $ROLE"

    switch ($Role)
    {
        'WSUS'{
            #Action
            $App = "Report Viewer 2008 SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\Report Viewer 2008 SP1\ReportViewer.exe'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallReportViewer2008SP1.ps1 -ArgumentList $Source -ErrorAction Stop -Credential $DefaultCred

            #Action
            $App = "SQLExpress"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Option = "Normal"
            $SQLSetup = 'D:\SQL 2014 Express SP1\SETUP.EXE'
            $SQLINSTANCENAME = "SQLExpress"
            $SQLINSTANCEDIR = "E:\SQLDB"
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014SP1Express.ps1 -ArgumentList $SQLSetup,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $DefaultCred

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $DefaultCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred
        }
        'VCompute'{
            #Stop VM
            Stop-VM -Name $($ServerData.VMName)

            #Configure for Hyper-v in Hyper-V
            Enable-VIANestedHyperV -VMname $($ServerData.VMName)

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMStart -VMname $($ServerData.VMName) -Credentials $DefaultCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred
        }
        'vConverged'{
            #Stop VM
            Stop-VM -Name $($ServerData.VMName)

            #Configure for Hyper-v in Hyper-V
            Enable-VIANestedHyperV -VMname $($ServerData.VMName)

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMStart -VMname $($ServerData.VMName) -Credentials $DefaultCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred
        }
        Default {
            Write-Host "Nothing todo for $Role"
        }
    }
}

#Add Roles And Features
Foreach($role in $roles){
    #Action
    $Action = "Add Roles And Features"
    Update-VIALog -Data "Action: $Action - $ROLE"
    $Return = Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
        Param(
        $Role
        )
        C:\Setup\HYDv10\Scripts\Invoke-VIAInstallRoles.ps1 -Role $ROLE
    } -ArgumentList $ROLE -ErrorAction Stop -Credential $DefaultCred
    $Return
}

#Restart
Update-VIALog -Data "Restart $($ServerData.VMName)"
Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $DefaultCred
if($ROLE -eq 'vConverged' -or 'VCompute'){Start-Sleep -Seconds 60}else{Start-Sleep -Seconds 20}
Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred

#Configure Roles And Features
foreach($Role in $Roles){
    #Action
    $Action = "Configure Roles And Features"
    Update-VIALog -Data "Action: $Action - $ROLE"
    switch ($Role)
    {
        'DEPL'{
            $DataDiskLabel = "DataDisk01"
            $RunAsAccount = "Administrator"
            $RunAsAccountPassword = $DomainAdminPassword
            Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARole-DEPL.ps1 -ArgumentList $DataDiskLabel,$RunAsAccount,$RunAsAccountPassword -ErrorAction Stop -Credential $domainCred
            
            $Action = "Share Applicationroot"
            Update-VIALog -Data "Action: $Action - $ROLE"
            Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                Param(
                $DataDiskLabel
                )
                $DriveLetter = (Get-Volume -FileSystemLabel $DataDiskLabel).DriveLetter
                $folders = 'ApplicationRoot'
                Foreach($folder in $folders){
                    New-Item -Path ($DriveLetter + ":\$folder") -ItemType Directory
                    New-SmbShare -Path ($DriveLetter + ":\$folder") -Name $folder -FullAccess Everyone
                }

                $folders = 'Scripts','Temp','Applications'
                Foreach($folder in $folders){
                    New-Item -Path ($DriveLetter + ":\ApplicationRoot\" + $folder) -ItemType Directory
                }
            } -ArgumentList $DataDiskLabel -Credential $domainCred
        }
        'RDGW'{
            $Group = "Domain Remote Desktop Users"
            $DomainNetBios = $DomainData.DomainNetBios
            $RemoteFQDN = "rdgw." + $DomainData.DNSDomainExternal
            Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARDGW01Config.ps1 -ArgumentList $Group,$DomainNetBios,$RemoteFQDN -Verbose -Credential $domainCred
        }
        'RRAS'{
            #Remove Net Route
            #TBA

            #Disable Remote Access
            Get-Service -Name RemoteAccess | Set-Service -StartupType Disabled

            #Add external Network Adapter
            $InternetID = '80c41589-c5fc-4785-a673-e8b08996cfc2'
            $ExternalNicName = (($Settings.settings.Servers.Server | Where-Object Name -EQ SNAT01).NetworkAdapters.NetworkAdapter | Where-Object ConnectedToNetwork -EQ $InternetID).Name
            $ExternalNetname = ($Settings.settings.Networks.Network | Where-Object id -EQ $InternetID).Name
            $RDGWIntIP = (($Settings.settings.Servers.Server | Where-Object Name -EQ RDGW01).NetworkAdapters.NetworkAdapter | Where-Object Name -EQ NIC01).IPAddress
            $RDGWExtIP = (($Settings.settings.Servers.Server | Where-Object Name -EQ RRAS01).NetworkAdapters.NetworkAdapter | Where-Object Name -EQ NIC02).IPAddress
            
            #Calculating Networkdata
            $FabricNetworkID = '9280db2e-6b5b-4770-9dd2-9e1f0292ea89'
            $FabricNetwork = $Settings.settings.Networks.Network | Where-Object -Property ID -EQ -Value $FabricNetworkID
            $InternalIPInterfaceAddressPrefix = ($FabricNetwork.NetIP + '/' + $FabricNetwork.SubNet)
            $ExternalIPAddress = '0.0.0.0'
            $ExternalPort = '443'
            $Protocol = 'TCP'
            $Internet = $NetworksData | Where-Object -Property Name -EQ -Value $ExternalNetname

            #Configure the external IP
            if($RDGWExtIP -ne 'DHCP'){
                Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                    Param(
                        $RDGWExtIP,$Subnet,$Gateway,$ExternalNicName
                    )
                    $NIC = Get-NetAdapter -Name $ExternalNicName
                    New-NetIPAddress -IPAddress $RDGWExtIP -ifIndex $NIC.ifIndex -DefaultGateway $Gateway -PrefixLength $Subnet
                    $NIC

                } -Credential $domainCred -ArgumentList $RDGWExtIP,$Internet.SubNet,$Internet.Gateway,$ExternalNicName
            }

            #Configure NAT rules
            Invoke-Command -VMName $($ServerData.VMName)  -ScriptBlock {
                Param(
                $RDGWIntIP,$InternalIPInterfaceAddressPrefix,$ExternalIPAddress,$ExternalPort,$Protocol,$ExternalNetname
                )
                New-NetNat -Name $ExternalNetname -InternalIPInterfaceAddressPrefix $InternalIPInterfaceAddressPrefix
                Add-NetNatStaticMapping -NatName $ExternalNetname -Protocol $Protocol -ExternalPort $ExternalPort -InternalIPAddress $RDGWIntIP -ExternalIPAddress $ExternalIPAddress
            } -Credential $domainCred -ArgumentList $RDGWIntIP,$InternalIPInterfaceAddressPrefix,$ExternalIPAddress,$ExternalPort,$Protocol,$ExternalNetname

            #Not Tested
            #Change Netbinding on th External NIC
            Invoke-Command -VMName $($ServerData.VMName)  -ScriptBlock {
                Param(
                $ExternalNicName
                )
                Get-NetAdapterBinding -Name $ExternalNicName | Where-Object -Property ComponentID -NE -Value "ms_tcpip" | Set-NetAdapterBinding -Enabled $false 
            } -Credential $domainCred -ArgumentList $ExternalNicName

        }
        'SNAT'{
            #Add external Network Adapter
            $InternetID = '80c41589-c5fc-4785-a673-e8b08996cfc2'
            $ExternalNicName = (($Settings.settings.Servers.Server | Where-Object Name -EQ SNAT01).NetworkAdapters.NetworkAdapter | Where-Object ConnectedToNetwork -EQ $InternetID).Name
            $ExternalNetname = ($Settings.settings.Networks.Network | Where-Object id -EQ $InternetID).Name
            
            $RDGWIntIP = (($Settings.settings.Servers.Server | Where-Object Name -EQ RDGW01).NetworkAdapters.NetworkAdapter | Where-Object Name -EQ NIC01).IPAddress
            $RDGWExtIP = (($Settings.settings.Servers.Server | Where-Object Name -EQ SNAT01).NetworkAdapters.NetworkAdapter | Where-Object Name -EQ NIC02).IPAddress
            
            #Calculating Networkdata
            $FabricNetworkID = '9280db2e-6b5b-4770-9dd2-9e1f0292ea89'
            $FabricNetwork = $Settings.settings.Networks.Network | Where-Object -Property ID -EQ -Value $FabricNetworkID
            $InternalIPInterfaceAddressPrefix = ($FabricNetwork.NetIP + '/' + $FabricNetwork.SubNet)
            $ExternalIPAddress = '0.0.0.0'
            $ExternalPort = '443'
            $Protocol = 'TCP'
            $Internet = $NetworksData | Where-Object -Property Name -EQ -Value $ExternalNetname

            #Configure the external IP
            if($RDGWExtIP -ne 'DHCP'){
                Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                    Param(
                        $RDGWExtIP,$Subnet,$Gateway,$ExternalNicName
                    )
                    $NIC = Get-NetAdapter -Name $ExternalNicName
                    New-NetIPAddress -IPAddress $RDGWExtIP -ifIndex $NIC.ifIndex -DefaultGateway $Gateway -PrefixLength $Subnet
                    $NIC

                } -Credential $domainCred -ArgumentList $RDGWExtIP,$Internet.SubNet,$Internet.Gateway,$ExternalNicName
            }

            #Configure NAT rules
            Invoke-Command -VMName $($ServerData.VMName)  -ScriptBlock {
                Param(
                $RDGWIntIP,$InternalIPInterfaceAddressPrefix,$ExternalIPAddress,$ExternalPort,$Protocol,$ExternalNetname
                )
                New-NetNat -Name $ExternalNetname -InternalIPInterfaceAddressPrefix $InternalIPInterfaceAddressPrefix

                try
                {
                    Add-NetNatStaticMapping -NatName $ExternalNetname -Protocol $Protocol -ExternalPort $ExternalPort -InternalIPAddress $RDGWIntIP -ExternalIPAddress $ExternalIPAddress
                }
                catch
                {
                    Write-Warning "Unable to create NAT rule"
                }

            } -Credential $domainCred -ArgumentList $RDGWIntIP,$InternalIPInterfaceAddressPrefix,$ExternalIPAddress,$ExternalPort,$Protocol,$ExternalNetname

            #Not Tested
            #Change Netbinding on th External NIC
            Invoke-Command -VMName $($ServerData.VMName)  -ScriptBlock {
                Param(
                $ExternalNicName
                )
                Get-NetAdapterBinding -Name $ExternalNicName | Where-Object -Property ComponentID -NE -Value "ms_tcpip" | Set-NetAdapterBinding -Enabled $false 
            } -Credential $domainCred -ArgumentList $ExternalNicName
        }
        'WSUS'{
            $DataDiskLabel = "DataDisk01"
            Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                Param(
                $DataDiskLabel
                )
                C:\Setup\HYDv10\Scripts\Set-VIARole-WSUS.ps1 -DataDiskLabel $DataDiskLabel
            } -ArgumentList $DataDiskLabel -ErrorAction Stop -Credential $domainCred
        }
        'ADDS'{
            #Action
            $Action = "Set vars for $Role"
            Write-Verbose "Action: $Action - $Role"
            $RoleConfig = ($Settings.settings.Roles.Role | Where-Object Name -EQ $Role | Where-Object Active -EQ $true)
            $ServerRoleConfig = ($ServerData.Roles.Role | Where-Object RoleUUID -EQ $RoleConfig.id).config
            Write-Verbose "Action: $Action - $Role - $ServerRoleConfig"
            switch ($ServerRoleConfig){
                'First'{
                    $Password = $DomainData.DomainAdminPassword
                    $FQDN = $DomainData.DNSDomain
                    $NetBiosDomainName = $DomainData.DomainNetBios
                    $SiteName = $DomainData.SiteName
                    $DomainForestLevel = ($Settings.settings.Roles.Role | Where-Object Name -EQ $Role | Where-Object Active -EQ $true).config.$ServerRoleConfig.DomainForestLevel
                    $DataDiskName = ($Settings.settings.Roles.Role | Where-Object Name -EQ $Role | Where-Object Active -EQ $true).config.$ServerRoleConfig.datadisk
                    
                    Write-Verbose "Action: Set new local admin password (to be inherted as domain admin password)"
                    $ScriptBlock = {
                        net user Administrator $Using:Password
                    }
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock $ScriptBlock -Credential $DefaultCred

                    Write-Verbose "Action: Generate new credentials"
                    $localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($ServerData.ComputerName)\Administrator", (ConvertTo-SecureString $Password -AsPlainText -Force)
                    $domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $Password -AsPlainText -Force)
                    if($DomainOrWorkGroup -eq 'Workgroup'){$DefaultCred = $localCred}
                    if($DomainOrWorkGroup -eq 'Domain'){$DefaultCred = $domainCred}

                    Write-Verbose "Action: executing Set-VIARole-ADDS.ps1"
                    $ScriptBlock = {
                        $DatabaseRoot = $(Get-Volume -FileSystemLabel $Using:DataDiskName).DriveLetter + ":\"
                        if((Test-Path -Path $DatabaseRoot) -eq $True){
                            Write-Verbose "NTDS will be located in $DatabaseRoot"
                        }else{
                            Write-Warning "The path $DatabaseRoot does not exists, switching to default values"
                            $DatabaseRoot = 'C:\Windows'
                        }
                        Write-Verbose "-Password $Using:Password -FQDN $Using:FQDN -NetBiosDomainName $Using:NetBiosDomainName -DomainForestLevel $Using:DomainForestLevel -DatabaseRoot $DatabaseRoot"
                        C:\Setup\HYDv10\Scripts\Set-VIARole-ADDS.ps1 -Password $Using:Password -FQDN $Using:FQDN -NetBiosDomainName $Using:NetBiosDomainName -DomainForestLevel $Using:DomainForestLevel -DatabaseRoot $DatabaseRoot -Config $Using:ServerRoleConfig
                    }
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock $ScriptBlock -Credential $DefaultCred

                    #Restart
                    $Action = "Restart $($ServerData.VMName)"
                    Write-Verbose "Action: $Action"
                    Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
                    Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred

                    #Wait for AD to be operational
                    $Action = "Wait for AD to be operational"
                    Write-Verbose "Action: $Action"
                    Wait-VIAVMADDSReady -VMname $($ServerData.VMName) -Credentials $domainCred

                    #Action
                    $Action = "SET sc.exe config NlaSvc start=delayed-auto"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        [cmdletbinding(SupportsShouldProcess=$True)]
                        Param(
                        )
                        sc.exe config NlaSvc start=delayed-auto
                        Restart-Service -Name NlaSvc -Force
                    } -Credential $domainCred

                    #Action
                    $Action = "Enable Active Directory Optional Features"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        [cmdletbinding(SupportsShouldProcess=$True)]
                        Param()
                        $FQDN = (Get-ADDomain).DNSRoot
                        $DomainDN = (Get-ADDomain).DistinguishedName
                        Enable-ADOptionalFeature –Identity "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$DomainDN" –Scope ForestOrConfigurationSet –Target "$FQDN" -Confirm:$false
                    } -Credential $domainCred

                    #Action
                    #Check if this is needed, seems to be set in 2016
                    $Action = "Enable Automatic DFSR Recovery"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\DFSR\Parameters -Name StopReplicationOnAutoRecovery -Value 0 -Force
                    } -Credential $domainCred

                    #Action
                    $Action = "Disable WMI as time provider"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider -Name Enabled -Value 0
                    } -Credential $domainCred

                    #Action
                    $Action = "Change AD Site name"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIAADDSSiteName.ps1 -ArgumentList $DomainData.SiteName -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Configure Subnets"
                    Write-Verbose "Action: $Action"
                    $ADSubnets = foreach($network in ($NetworksData | Where-Object -Property NetIP -NE -Value 'NA')){
                        "$($network.NetIP)/$($network.SubNet)"
                    }
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIAADSiteSubnet.ps1 -ArgumentList $DomainData.SiteName,$ADSubnets -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Adding default Rev DNS Zones"
                    Write-Verbose "Action: $Action"
                    Start-Sleep 60
                    $RevDNSZones = ($Settings.settings.Networks.Network| Where-Object -Property RDNS -Like *in-addr.arpa).rdns
                    foreach($RevDNSZone in $RevDNSZones){
                        Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIAADDSRevDNSZone.ps1 -ArgumentList $RevDNSZone -ErrorAction Continue -Verbose -Credential $domainCred
                    }

                    #Action
                    $Action = "Remove DNS Forwarders"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        [cmdletbinding(SupportsShouldProcess=$True)]
                        Param(
                        )
                        Get-DnsServerForwarder | Remove-DnsServerForwarder -Force
                    } -ErrorAction SilentlyContinue -Credential $domainCred

                    #Action
                    $Action = "Configure Client DNS"
                    Write-Verbose "Action: $Action"
                    $ClientDNSServerAddr = "$($NIC01.DNS[0]),$($NIC01.DNS[1])"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        [cmdletbinding(SupportsShouldProcess=$True)]
                        Param(
                        $ClientDNSServerAddr
                        )
                        C:\Setup\HYDv10\Scripts\Set-VIAADClientDNSSettings.ps1 -ClientDNSServerAddr $ClientDNSServerAddr
                    } -ArgumentList $ClientDNSServerAddr -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Create base OU"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\New-VIAADBaseOU.ps1 -ArgumentList $DomainData.BaseOU -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Create Sub OUs"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\New-VIAADStructure.ps1 -ArgumentList $($DomainData.BaseOU),$($DomainData.DomainOUs.DomainOU | Where-Object Active -EQ True) -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Create AD Groups"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\New-VIAADGroups.ps1 -ArgumentList $($DomainData.BaseOU),$($DomainData.DomainGroups.DomainGroup | Where-Object Active -EQ True) -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Create AD Accounts"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\New-VIAADAccount.ps1 -ArgumentList $($DomainData.BaseOU),$($DomainData.DomainAccounts.DomainAccount | Where-Object Active -EQ True) -ErrorAction Stop -Credential $domainCred

                    #Action
                    $Action = "Add User to Groups"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\New-VIAAddAccountToGroups.ps1 -ArgumentList $($DomainData.BaseOU),$($DomainData.DomainAccounts.DomainAccount | Where-Object Active -EQ True) -ErrorAction Stop -Credential $domainCred
                }
                'Last'{
                    $Password = $DomainData.DomainAdminPassword
                    $FQDN = $DomainData.DNSDomain
                    $NetBiosDomainName = $DomainData.DomainNetBios
                    $SiteName = $DomainData.SiteName
                    $DomainForestLevel = ($Settings.settings.Roles.Role | Where-Object Name -EQ $Role | Where-Object Active -EQ $true).config.$ServerRoleConfig.DomainForestLevel
                    $DataDiskName = ($Settings.settings.Roles.Role | Where-Object Name -EQ $Role | Where-Object Active -EQ $true).config.$ServerRoleConfig.datadisk

                    $ScriptBlock = {
                        $DatabaseRoot = $(Get-Volume -FileSystemLabel $Using:DataDiskName).DriveLetter + ":\"
                        if((Test-Path -Path $DatabaseRoot) -eq $True){
                            Write-Verbose "NTDS will be located in $DatabaseRoot"
                        }else{
                            Write-Warning "The path $DatabaseRoot does not exists, switching to default values"
                            $DatabaseRoot = 'C:\Windows'
                        }
                        Write-Verbose "-Password $Using:Password -FQDN $Using:FQDN -NetBiosDomainName $Using:NetBiosDomainName -DomainForestLevel $Using:DomainForestLevel -DatabaseRoot $DatabaseRoot"
                        C:\Setup\HYDv10\Scripts\Set-VIARole-ADDS.ps1 -Password $Using:Password -FQDN $Using:FQDN -NetBiosDomainName $Using:NetBiosDomainName -DomainForestLevel $Using:DomainForestLevel -DatabaseRoot $DatabaseRoot -Config $Using:ServerRoleConfig -SiteName $Using:SiteName
                    }
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock $ScriptBlock -Credential $DefaultCred

                    #Restart
                    Update-VIALog -Data "Restart $($ServerData.VMName)"
                    Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $DefaultCred
                    Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred

                    #Wait for AD to be operational
                    Update-VIALog -Data "Wait for AD to be operational"
                    Wait-VIAVMADDSReady -VMname $($ServerData.VMName) -Credentials $domainCred

                    #Action
                    $Action = "SET sc.exe config NlaSvc start=delayed-auto"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        [cmdletbinding(SupportsShouldProcess=$True)]
                        Param(
                        )
                        sc.exe config NlaSvc start=delayed-auto
                        Restart-Service -Name NlaSvc -Force
                    } -Credential $domainCred

                    #Action
                    #Check if this is needed, seems to be set in 2016
                    $Action = "Enable Automatic DFSR Recovery"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\DFSR\Parameters -Name StopReplicationOnAutoRecovery -Value 0 -Force
                    } -Credential $domainCred

                    #Action
                    $Action = "Disable WMI as time provider"
                    Write-Verbose "Action: $Action"
                    Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                        Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider -Name Enabled -Value 0
                    } -Credential $domainCred
                }
                Default{
                }
            }
        }
        'DHCP'{
            #Action
            $Action = "Set vars for $Role"
            Write-Verbose "Action: $Action - $Role"
            $RoleConfig = ($Settings.settings.Roles.Role | Where-Object Name -EQ $Role | Where-Object Active -EQ $true)
            $ServerRoleConfig = ($ServerData.Roles.Role | Where-Object RoleUUID -EQ $RoleConfig.id).config
            Write-Verbose "Action: $Action - $Role - $ServerRoleConfig"

            #Action
            $Action = "Base Configure DHCP"
            Write-Verbose "Action: $Action - $Role"
            Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARole-DHCP.ps1 -Credential $domainCred

            if($ServerRoleConfig -eq 'First'){
                #Action
                $Action = "Create DHCP Scopes"
                Write-Verbose "Action: $Action"
                Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARole-DHCP-Create-Scope.ps1 -ArgumentList $($NIC01RelatedData.NetIP), $($NIC01RelatedData.SubNet), $($NIC01RelatedData.DHCPStart), $($NIC01RelatedData.DHCPEnd), $($DomainData.DNSDomain), $($NIC01RelatedData.DNS[0]), $($NIC01RelatedData.DNS[1]), $($NIC01RelatedData.Gateway) -ErrorAction Stop -Credential $domainCred
            }

            if($ServerRoleConfig -eq 'Last'){
                #Action
                $Action = "Configure DHCP Replication"
                Write-Output "Action: $Action - $Role"
                Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                    Param(
                        $PriDHCPServer,
                        $SecDHCPServer
                    )
                    $Scopes = Get-DhcpServerv4Scope -ComputerName $PriDHCPServer
                    $Scopes.ScopeId
                    Add-DhcpServerv4Failover -ComputerName $PriDHCPServer -Name ($PriDHCPServer + '-' +$SecDHCPServer) -PartnerServer $SecDHCPServer -ScopeId $Scopes.ScopeId -LoadBalancePercent 70 -MaxClientLeadTime 2:00:00 -AutoStateTransition $true -StateSwitchInterval 2:00:00
                } -Credential $domainCred -ArgumentList ($Settings.settings.Servers.Server | Where-Object -Property Name -EQ ADDS01).computername,($Settings.settings.Servers.Server | Where-Object -Property Name -EQ ADDS02).computername
            }
            #Action
            $Action = "Configure DHCP..."
            $DHCPServiceAccountDomain = $DomainData.DomainNetBios
            $DHCPServiceAccountName = ($DomainData.DomainAccounts.DomainAccount | Where-Object Name -EQ 'SVC_ADDS_DHCP').name
            $DHCPServiceAccountPW = ($DomainData.DomainAccounts.DomainAccount | Where-Object Name -EQ 'SVC_ADDS_DHCP').PW
            Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                [cmdletbinding(SupportsShouldProcess=$True)]
                Param(
                    $DHCPServiceAccountDomain,$DHCPServiceAccountName,$DHCPServiceAccountPW
                )
                Set-DhcpServerv4DnsSetting -UpdateDnsRRForOlderClients $true 
                Set-DhcpServerv4DnsSetting -NameProtection $true
                $DHCPSrvCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$($DHCPServiceAccountDomain)\$($DHCPServiceAccountName)", (ConvertTo-SecureString $DHCPServiceAccountPW -AsPlainText -Force)
                Set-DhcpServerDnsCredential -Credential $DHCPSrvCred
            } -ErrorAction SilentlyContinue -Credential $domainCred -ArgumentList $DHCPServiceAccountDomain,$DHCPServiceAccountName,$DHCPServiceAccountPW
        }
        'ADCA'{
            #Set param
            $RunAsAccount = "Administrator"
            $RunAsAccountPassword = $DomainAdminPassword
            $CACommonName = 'Fabric-root-CA'
            $CARootCertLifeTimeYear = '12'
            $CARootCertHashAlgorithmName = 'SHA256' 
            $CARootCertKeyLengt = '2048'
            
            #Install CA
            Invoke-Command -VMName $($ServerData.VMName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARole-ADCA.ps1 -ArgumentList $RunAsAccount,$RunAsAccountPassword,$CACommonName,$CARootCertLifeTimeYear,$CARootCertHashAlgorithmName,$CARootCertKeyLengt -Verbose -Credential $domainCred
            
            C:\Setup\HYDv10\Scripts\Set-VIARole-ADCA.ps1 -RunAsAccount -RunAsAccountPassword -CACommonName -CARootCertLifeTimeYear -CARootCertHashAlgorithmName -CARootCertKeyLengt

            #Reboot Number 1
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $DefaultCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred
            Start-Sleep -Seconds 30
            
            #Reboot Number 2
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $DefaultCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $DefaultCred
        }
        Default {}
    }
}

#Install Applications (Post Roles and Features)
foreach($Role in $Roles){
    #Action
    $Action = "Install Applications (Post Roles and Features)"
    Update-VIALog -Data "Action: $Action - $ROLE"
    switch ($Role)
    {
        'DEPL'{
            #Action
            $App = "ADK 1607"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\Windows ADK 10 1607\adksetup.exe'
            $Configuration = "MDT"
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallADK.ps1 -ArgumentList $Source,$Configuration -ErrorAction Stop -Credential $domainCred 

            #Action
            $App = "MDT 8443"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\MDT 8443\MicrosoftDeploymentToolkit_x64.msi'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallMDT.ps1 -ArgumentList $Source -ErrorAction Stop  -Credential $domainCred
        }
        'SCVM2016'{
            #Action
            $App = "ADK 1607"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\Windows ADK 10 1607\adksetup.exe'
            $Configuration = "SCVM2016"
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallADK.ps1 -ArgumentList $Source,$Configuration -ErrorAction Stop -Credential $domainCred 

            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLINSTANCENAME = "MSSQLSERVER"
            $SQLINSTANCEDIR = "E:\SQLDB"
            $SQLRole = 'SCVM2016'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "SCVMM 2016"
            $Action = "Add Service Account to Local Administrators Group"
            Update-VIALog -Data "Action: $Action - $App"
            $LocalGroup = "Administrators"
            $DomainUser = ($DomainData.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCVMM').Name
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -ArgumentList $LocalGroup,$DomainUser -ErrorAction Stop  -Credential $domainCred

            #Restart
            $App = "Server"
            $Action = "Restart"
            Update-VIALog -Data "Action: $Action - $App"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred

            #Action
            $App = "SCVMM 2016"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $ServiceAccount = $DomainData.DomainAccounts.DomainAccount| Where-Object AccountDescription -EQ 'Service Account for SCVMM'
            $Service01 = $Settings.settings.Services.Service | Where-Object Name -EQ SCVMM2016
            $Source = 'D:\SC 2016 VMM\setup.exe'
            $SCVMRole = 'Full'
            $SCVMMDomain = $DomainName
            $SCVMMSAccount =  $ServiceAccount.Name
            $SCVMMSAccountPW = $ServiceAccount.PW
            $SCVMMProductKey = 'BXH69-M62YX-QQD6R-3GPWX-8WMFY'
            $SCVMMUserName = $CustomerData.Name
            $SCVMMCompanyName = $CustomerData.Name
            $Service01.Config.SCVMMBitsTcpPort
            $SCVMMBitsTcpPort = $Service01.Config.SCVMMBitsTcpPort
            $SCVMMVmmServiceLocalAccount = '0'
            $SCVMMTopContainerName = "cn=dkm,"+$DomainData.DomainDS
            $SCVMMLibraryDrive = 'E:'
            Invoke-Command -VMName $ServerData.VMName -Scriptblock{
                Param(
                $Source,
                $SCVMRole,
                $SCVMMDomain,
                $SCVMMSAccount,
                $SCVMMSAccountPW,
                $SCVMMProductKey,
                $SCVMMUserName,
                $SCVMMCompanyName,
                $SCVMMBitsTcpPort,
                $SCVMMVmmServiceLocalAccount,
                $SCVMMTopContainerName,
                $SCVMMLibraryDrive
                )
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCVM2016.ps1 $Source $SCVMRole $SCVMMDomain $SCVMMSAccount $SCVMMSAccountPW $SCVMMProductKey $SCVMMUserName $SCVMMCompanyName $SCVMMBitsTcpPort $SCVMMVmmServiceLocalAccount $SCVMMTopContainerName $SCVMMLibraryDrive
            } -ArgumentList $Source,$SCVMRole,$SCVMMDomain,$SCVMMSAccount,$SCVMMSAccountPW,$SCVMMProductKey,$SCVMMUserName,$SCVMMCompanyName,$SCVMMBitsTcpPort,$SCVMMVmmServiceLocalAccount,$SCVMMTopContainerName,$SCVMMLibraryDrive -ErrorAction Stop  -Credential $domainCred
        }
        'SCOM2016'{
            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLINSTANCENAME = "MSSQLSERVER"
            $SQLINSTANCEDIR = "E:\SQLDB"
            $SQLRole = 'SCOM2016'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred
            
            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred
            
            #Action
            $App = "SCOM 2016"
            $Action = "Add Service Account to Local Administrators Group"
            Update-VIALog -Data "Action: $Action - $App"
            $LocalGroup = "Administrators"
            $DomainUser = ($DomainData.DomainAccounts.DomainAccount| Where-Object AccountDescription -EQ 'Service Account for SCOM').Name
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -ArgumentList $LocalGroup,$DomainUser -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "SCOM 2016 Server"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install OpsMgr Server
            $ServiceAccount = $DomainData.DomainAccounts.DomainAccount| Where-Object AccountDescription -EQ 'Service Account for SCOM'
            $ActionAccount = $DomainData.DomainAccounts.DomainAccount| Where-Object AccountDescription -EQ 'Action Account for SCOM'
            $Service01 = $Settings.settings.Services.Service | Where-Object Name -EQ SCOM2016
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMServer'
            Invoke-Command -VMName $($ServerData.VMName) -Scriptblock{
                Param(
                $Source,
                $SCOMRole,
                $ManagementGroupName,
                $SqlServerInstance,
                $DWSqlServerInstance,
                $DatareaderUser,
                $DatareaderPassword,
                $ActionAccountUser,
                $ActionAccountPassword
                )
                Write-Verbose "Using: $Source $SCOMRole $ManagementGroupName $SqlServerInstance $DWSqlServerInstance $DatareaderUser $DatareaderPassword $ActionAccountUser $ActionAccountPassword"
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -ManagementGroupName $ManagementGroupName -SqlServerInstance $SqlServerInstance -DWSqlServerInstance $DWSqlServerInstance -DatareaderUser $DatareaderUser -DatareaderPassword $DatareaderPassword -DataWriterUser $DatareaderUser -DataWriterPassword $DatareaderPassword -DASAccountUser $DatareaderUser -DASAccountPassword $DatareaderPassword -ActionAccountUser $ActionAccountUser -ActionAccountPassword $ActionAccountPassword
            } -ArgumentList $Source,$SCOMRole,$($DomainData.DomainNetBios),$($Service01.Config.SQLINSTANCENAME),$($Service01.Config.SQLINSTANCENAME),$($($DomainData.DomainNetBios)+'\'+$($ServiceAccount.Name)),$($ServiceAccount.PW),$($($DomainData.DomainNetBios)+'\'+$($ActionAccount.Name)),$($ActionAccount.PW) -ErrorAction Stop  -Credential $domainCred

    
            #Action
            $App = "SCOM 2016 Console"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install Console
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMConsole'
            Invoke-Command -VMName $ServerData.VMName -Scriptblock{
                Param(
                $Source,
                $SCOMRole
                )
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -Verbose
            }-ArgumentList $Source,$SCOMRole -Credential $domainCred

            #Action
            $App = "SCOM 2016 Reporting"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install Reporting
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMReporting'
            Invoke-Command -VMName $ServerData.VMName -Scriptblock{
                Param(
                $Source,
                $SCOMRole,
                $ServiceAccountName,
                $ServiceAccountPW,
                $SqlServerInstance
                )
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -DataWriterUser $ServiceAccountName -DataWriterPassword $ServiceAccountPW -SRSInstance $SqlServerInstance
            } -ArgumentList $Source,$SCOMRole,$($($DomainData.DomainNetBios)+'\'+$($ServiceAccount.Name)),$($ServiceAccount.PW),$($Service01.Config.SQLINSTANCENAME) -Credential $domainCred 

            #Action
            $App = "SCOM 2016 WebConsole"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install WebConsole
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMWebConsole'
            Invoke-Command -VMName $ServerData.VMName -Scriptblock{
                Param(
                $Source,
                $SCOMRole
                )
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -WebSiteName "Default Web Site"
            } -ArgumentList $Source,$SCOMRole -Credential $domainCred 

            #Action
            $App = "SCOM 2016"
            $Action = "Configure Automatic Agent Assigment"
            Update-VIALog -Data "Action: $Action - $App"
            $SCOMManagementGroupName = $DomainName
            $SCOMAdminSecurityGroup = "$DomainName\Domain System Center Operations Manager Admins"
            $SCOMRunAsAccount = "$DomainName\SVC_SCOM_AA"
            $Domain = $DomainName
            Invoke-Command -VMName $ServerData.VMName -Scriptblock{
                Param(
                $ManagementGroupName,
                $MOMAdminSecurityGroup,
                $RunAsAccount,
                $Domain
                )
                 & 'C:\Program Files\Microsoft System Center 2016\Operations Manager\Server\MomADAdmin.exe' $ManagementGroupName $MOMAdminSecurityGroup $RunAsAccount $Domain
            } -ArgumentList $SCOMManagementGroupName,$SCOMAdminSecurityGroup,$SCOMRunAsAccount,$Domain -Credential $domainCred


            #Action
            $App = "SCOM 2016"
            $Action = "Add Product Key and Activate SCOM"
            $ProductKey = ($Settings.settings.ProductKeys.ProductKey | Where-Object -Property Name -EQ -Value ProduktKeySC2016).key
            if($ProductKey -ne 'NA'){
                Update-VIALog -Data "Action: $Action - $App"
                Invoke-Command -VMName $ServerData.VMName -Scriptblock{
                    Param(
                    $ProductId
                    )
                    Import-Module 'C:\Program Files\Microsoft System Center 2016\Operations Manager\Powershell\OperationsManager'
                    Set-SCOMLicense -ProductId $ProductId -Confirm:$false -Verbose
                    Restart-Service "System Center Management Configuration" -Force
                    Restart-Service "System Center Data Access Service" -Force
                } -ArgumentList $ProductKey -Credential $domainCred
            }
            else{
                Write-Verbose "No productkey specified"
            }

            #Install SCVMM Client
            $App = "SCOR 2016"
            $Action = "Install SCVMM Client"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                $result = Start-Process -FilePath 'D:\SC 2016 VMM\setup.exe' -ArgumentList " /client /i /IACCEPTSCEULA" -NoNewWindow -PassThru -Wait
                $result.ExitCode
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred
        }
        'SCDP2016'{
            #Get Servicedata
            $ServicesData = $Settings.settings.Services.Service | Where-Object -Property Name -EQ -Value 'SCDP2016'
            $SQLINSTANCENAME = $ServicesData.config.SQLINSTANCENAME
            $SQLINSTANCEDIR = "E:\$($ServicesData.config.SQLINSTANCEDIR)"

            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLRole = 'SCDP2016'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred

            #Action
            $App = "SC DPM 2016"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SC 2016 DPM\Setup.exe'
            $SQLINSTANCENAME = ($ServicesData | Where-Object Name -EQ SCDP2016).config.SQLINSTANCENAME
            $Role = 'Full'
            $Domain = $DomainData.Name
            $ProductKey = ($ProductKeysData | Where-Object Name -EQ ProduktKeySC2016).key
            $UserName = $CustomerData.Name
            $CompanyName = $CustomerData.Name
            $SqlAccountPassword = "P@ssw0rd"
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock {
                Param($Source,$Role,$Domain,$ProductKey,$UserName,$CompanyName,$SQLINSTANCENAME,$SqlAccountPassword)
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCDP2016.ps1 -Source $Source -Role $Role -Domain $Domain -ProductKey $ProductKey -UserName $UserName -CompanyName $CompanyName -SQLINSTANCENAME $SQLINSTANCENAME -SqlAccountPassword $SqlAccountPassword
            } -ArgumentList $Source,$Role,$Domain,$ProductKey,$UserName,$CompanyName,$SQLINSTANCENAME,$SqlAccountPassword -ErrorAction Stop  -Credential $domainCred
        }
        'SCCM_CB'{
            #Get Servicedata
            #$ServicesData = $Settings.settings.Services.Service | Where-Object -Property Name -EQ -Value 'SCDP2016'
            $SQLINSTANCENAME = 'MSSQLServer'
            $SQLINSTANCEDIR = "E:\SQLDB"

            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLRole = 'SCCM_CB'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "SQL Firewall Rules"
            $Action = "Configure Application"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                New-NetFirewallRule -Name "SQL ports for ConfigMgr" -Enabled True -DisplayName "SQL ports for ConfigMgr" -Profile Domain -Protocol TCP -LocalPort 1433,4022
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "SQL Memory Config"
            $Action = "Configure Application"
            Update-VIALog -Data "Action: $Action - $App"
            $SQLRole = 'SCCM_CB'
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Set-VIASQLMemoryConfiguration.ps1 -ArgumentList $SQLINSTANCENAME -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "Add System to System"
            $Action = "Configure Application"
            Update-VIALog -Data "Action: $Action - $App"
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock {
                C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -LocalGroup Administrators -DomainUser CM01$
            } -Credential $domainCred

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred

            #Action
            $App = "Extend AD"
            $Action = "Configure Application"
            Update-VIALog -Data "Action: $Action - $App"
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock {
                & 'D:\ConfigMgr CB\Source\SMSSETUP\BIN\X64\extadsch.exe'
            } -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "Create/Configure System Managment Container"
            $Action = "Configure Application"
            Update-VIALog -Data "Action: $Action - $App"
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock {
                Add-WindowsFeature -Name 'RSAT-AD-PowerShell','RSAT-ADDS','RSAT-AD-AdminCenter','RSAT-ADDS-Tools' -IncludeAllSubFeature
                C:\Setup\HYDv10\Scripts\Create-CCMContainer.ps1
            } -Credential $domainCred

            #Action
            $App = "SCCM CB"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\ConfigMgr CB\Source\SMSSETUP\BIN\X64\setup.exe'
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock {
                Param()
                & 'D:\ConfigMgr CB\Source\SMSSETUP\BIN\X64\setup.exe' /script C:\Setup\HYDv10\Scripts\ConfigMgrUnattend.ini /NoUserInput
            } -ErrorAction Stop  -Credential $domainCred
        }
        'SCOR2016'{
            #Get Servicedata
            $ServicesData = $Settings.settings.Services.Service | Where-Object -Property Name -EQ -Value 'SCOR2016'
            $SQLINSTANCENAME = $ServicesData.Config.SQLINSTANCENAME
            $SQLINSTANCEDIR = "E:\$($ServicesData.Config.SQLINSTANCEDIR)"
            $ServicesData.Config
            Write-Verbose "SQLINSTANCENAME: $SQLINSTANCENAME"
            Write-Verbose "SQLINSTANCEDIR: $SQLINSTANCEDIR"

            #Action
            $App = "SCOR 2016"
            $Action = "Install SQL 2014 STD SP1"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLRole = $Role
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Set vars for SCOR install
            $ServiceAccount = $DomainData.DomainAccounts.DomainAccount | Where-Object -Property Name -EQ -Value SVC_SCOR_SA
            $SCORSAccount = "$($DomainData.DomainNetBios)\$ServiceAccountName"
            $SCORSAccountPW = $ServiceAccount.PW
            $SCORInstallAccount = "$($DomainData.DomainNetBios)\$ServiceAccountName"
            $SCORProductKey = ($ProductKeysData | where Name -EQ ProduktKeySC2016).key

            Write-Verbose "SCORSAccount: $SCORSAccount"
            Write-Verbose "SSCORSAccountPW: $SCORSAccountPW"
            Write-Verbose "SCORDBSrv: $SCORDBSrv"
            Write-Verbose "SCORInstallAccount: $SCORInstallAccount"
            Write-Verbose "SCORProductKey: $SCORProductKey"

            #Action
            $App = "SCOR 2016"
            $Action = "Add $ServiceAccountName to local Administrators group"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -LocalGroup Administrators -DomainUser $using:ServiceAccountName
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Action
            $App = "SCOR 2016"
            $Action = "Install SCOR2016"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOR2016.ps1 -Setup "D:\SC 2016 OR\Setup\Setup.exe" -SCORProductKey $Using:SCORProductKey -SCORSAccount $Using:SCORSAccount -SCORSAccountPW $Using:SCORSAccountPW -SCORDBSrv $($Env:Computername +'\' + $Using:SQLINSTANCENAME) -Verbose
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Firewall rule for SCOR 2016
            $App = "SCOR 2016"
            $Action = "Open port 81 and 82"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                New-NetFirewallRule -Name SCOR2016 -DisplayName "System Center Orchestrator" -Description "System Center Orchestrator" -Protocol TCP -LocalPort 81-82 -Enabled True -Profile Any -Action Allow 
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Set vars for SPF Install
            $ServiceAccount = $DomainData.DomainAccounts.DomainAccount | Where-Object -Property Name -EQ -Value SVC_SPF_SA
            $SPFServiceAccount = $ServiceAccount.Name
            $SPFServiceAccountPW = $ServiceAccount.PW
            $ServiceAccount = $DomainData.DomainAccounts.DomainAccount | Where-Object -Property Name -EQ -Value SVC_WAP_SA
            $WAPServiceAccount = $ServiceAccount.Name
            $VmmSecurityGroupUsers = $ServicesData.Config.VmmSecurityGroupUsers
            $AdminSecurityGroupUsers = $ServicesData.Config.AdminSecurityGroupUsers
            $ProviderSecurityGroupUsers = $ServicesData.Config.ProviderSecurityGroupUsers
            $usageSecurityGroupUsers = $ServicesData.Config.usageSecurityGroupUsers

            Write-Verbose "SPFServiceAccount: $SPFServiceAccount"
            Write-Verbose "SPFServiceAccountPW: $SPFServiceAccountPW"
            Write-Verbose "WAPServiceAccount: $WAPServiceAccount"
            Write-Verbose "VmmSecurityGroupUsers: $VmmSecurityGroupUsers"
            Write-Verbose "AdminSecurityGroupUsers: $AdminSecurityGroupUsers"
            Write-Verbose "ProviderSecurityGroupUsers: $ProviderSecurityGroupUsers"
            Write-Verbose "usageSecurityGroupUsers: $usageSecurityGroupUsers"

            #Add Roles And Features for SPF2016
            $App = "SCOR 2016"
            $Action = "Add Roles And Features for SPF2016"
            Update-VIALog -Data "Action: $Action - $App"
            $Return = Invoke-Command -VMName $($ServerData.VMName) -ScriptBlock {
                Param(
                $Role
                )
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallRoles.ps1 -Role $ROLE
            } -ArgumentList SPF2016 -ErrorAction Stop -Credential $DefaultCred

            #Action
            $App = "SCOR 2016"
            $Action = "Add $WAPServiceAccount to local Administrators group"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -LocalGroup Administrators -DomainUser $using:WAPServiceAccount
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Install Windows Communication Foundation (WCF) Data Services 5.0 for Open Data Protocol (OData) V3
            $App = "SCOR 2016"
            $Action = "Install Windows Communication Foundation (WCF) Data Services 5.0 for Open Data Protocol (OData) V3"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallWCF.ps1 -Setup D:\WcfDataServices5\WcfDataServices.exe 
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Install ASPNET4
            $App = "SCOR 2016"
            $Action = "Install ASPNET4"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallAspNetMVC4Setup.ps1 -Setup D:\AspNetMVC4\AspNetMVC4Setup.exe 
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Install SCVMM Client
            $App = "SCOR 2016"
            $Action = "Install SCVMM Client"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                $result = Start-Process -FilePath 'D:\SC 2016 VMM\setup.exe' -ArgumentList " /client /i /IACCEPTSCEULA" -NoNewWindow -PassThru -Wait
                $result.ExitCode
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            $App = "SCOR 2016"
            $Action = "Install SPF2016"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSPF2016.ps1 -SPFSetup "D:\SC 2016 OR\SPF\Setup.exe" `
                -SPFDomain $Using:DomainData.DomainNetBios `
                -SPFServiceAccount $using:SPFServiceAccount `
                -SPFServiceAccountPW $using:SPFServiceAccountPW `
                -DatabaseServer $env:COMPUTERNAME `
                -VmmSecurityGroupUsers """$($Using:DomainData.DomainNetBios)\$($Using:VmmSecurityGroupUsers)""" `
                -AdminSecurityGroupUsers """$($Using:DomainData.DomainNetBios)\$($Using:AdminSecurityGroupUsers)""" `
                -ProviderSecurityGroupUsers """$($Using:DomainData.DomainNetBios)\$($Using:ProviderSecurityGroupUsers)""" `
                -usageSecurityGroupUsers """$($Using:DomainData.DomainNetBios)\$($Using:usageSecurityGroupUsers)""" -Verbose
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Set vars for SMA Install
            $ServiceAccount = $DomainData.DomainAccounts.DomainAccount | Where-Object -Property Name -EQ -Value SVC_SMA_SA
            $SMAServiceAccount = $ServiceAccount.Name
            $SMAServiceAccountPW = $ServiceAccount.PW
            $SMADBServer = $ServicesData.Config.SMADBServer
            $SMADBPort = $ServicesData.Config.SMADBPort
            $SMADBName = $ServicesData.Config.SMADBName
            $SMADBAuth = $ServicesData.Config.SMADBAuth
            $SMAAccessGroup = $ServicesData.Config.SMAAccessGroup

            Write-Verbose "SMADBServer: $SMADBServer"
            Write-Verbose "SMADBPort: $SMADBPort"
            Write-Verbose "SMADBName: $SMADBName"
            Write-Verbose "SMADBAuth: $SMADBAuth"
            Write-Verbose "SMAAccessGroup: $SMAAccessGroup"

            #Action
            $App = "SCOR 2016"
            $Action = "Add $SMAServiceAccount to local Administrators group"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -LocalGroup Administrators -DomainUser $using:SMAServiceAccount
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            # Install SMA Powershell Module 
            $App = "SCOR 2016"
            $Action = "Install SMA PowershellModuleInstaller.msi"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                $Result = Start-Process msiexec.exe -ArgumentList "/i ""D:\SC 2016 OR\SMA\PowershellModuleInstaller.msi"" /qn" -Wait -NoNewWindow -PassThru -Verbose
                $result.ExitCode
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            # Install SMA
            $App = "SCOR 2016"
            $Action = "Install SMA WebServiceInstaller.msi"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                $Cert = Get-ChildItem Cert:\LocalMachine\My | where -Property Subject -like "CN=$env:COMPUTERNAME.$DNSDomain" | where -Property Issuer -NotLike "CN=$env:COMPUTERNAME.$DNSDomain" 
                if ($Cert) { 
                    $SPECIFYCERTIFICATE = "Yes"
                    $CertSerial = $Cert.SerialNumber
                } 
                else { 
                    $SPECIFYCERTIFICATE = "No" 
                } 
                $Domain = $($Using:DomainData.DomainNetBios)
                $AppPoolAccount = "$Domain"+"\"+"$Using:SMAServiceAccount"
                $ADMINGROUPMEMBERS = "$Domain"+"\"+"$Using:SMAAccessGroup"
                $AppPoolAccount = "$Domain"+"\"+"$Using:SMAServiceAccount"
                $CreateDatabase = "Yes"
                $SMASQLServer = $Using:SMADBServer+", "+$Using:SMADBPort 

                $SMAPARAMETERS = "APPOOLACCOUNT=""$AppPoolAccount"" ApPOOLPASSWORD=""$Using:SMAServiceAccountPW"" ADMINGROUPMEMBERS=""$ADMINGROUPMEMBERS"" CREATEDATABASE=""$CreateDatabase"" DATABASEAUTHENTICATION=""$Using:SMADBAuth"" SQLSERVER=""$SMASQLServer"" SPECIFYCERTIFICATE=""$SPECIFYCERTIFICATE"" CERTIFICATESERIAL=""$CertSerial"" PRODUCTKEY=""$Using:SCORProductKey""" 
                $result = Start-Process msiexec.exe -ArgumentList "/i ""D:\SC 2016 OR\SMA\WebServiceInstaller.msi"" /qn /L*v $ENV:Temp\WebServiceInstaller2.log $SMAPARAMETERS" -Wait -NoNewWindow -PassThru -Verbose
                $result.ExitCode
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            # Install SMA
            $App = "SCOR 2016"
            $Action = "Install SMA WorkerInstaller.msi"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                $Domain = $($Using:DomainData.DomainNetBios)
                $AppPoolAccount = "$Domain"+"\"+"$Using:SMAServiceAccount"
                $SMASQLServer = $Using:SMADBServer+", "+$Using:SMADBPort 
                $SMARWPARAMETERS = "SERVICEACCOUNT=""$AppPoolAccount"" SERVICEPASSWORD=""$Using:SMAServiceAccountPW"" DATABASEAUTHENTICATION=""$Using:SMADBAuth"" SQLSERVER=""$SMASQLServer"" PRODUCTKEY=""$Using:SCORProductKey""" 
                $Result = Start-Process msiexec.exe -ArgumentList "/i ""D:\SC 2016 OR\SMA\WorkerInstaller.msi"" /qn /L*v $ENV:Temp\RBWebServiceInstaller.log $SMAPARAMETERS" -Wait -NoNewWindow -PassThru -Verbose
                Return $Result
            }
            $Result = Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred
            Write-Verbose "Exitcode from $Action was: $($Result.ExitCode)"

            #Test Retur
            #$App = "Test Retur"
            #$Action = "Test Retur"
            #Update-VIALog -Data "Action: $Action - $App"
            #$ScriptBlock = {
            #    $Result = Start-Process cmd.exe -ArgumentList "/c dir c:\" -Wait -NoNewWindow -PassThru -Verbose
            #    Return $Result
            #}
            #$Result = Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred
            #$Result.Exitcode

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred
        }
        'WAP'{
            #Action
            $App = "WAP"
            $Action = "SQL 2014 Express SP1"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 Express SP1\SETUP.EXE'
            $SQLINSTANCENAME = "MSSQLSERVER"
            $SQLINSTANCEDIR = "E:\SQLDB"
            $SecurityMode = "Mixed"
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014SP1Express.ps1 -ArgumentList $Source,$SQLINSTANCENAME,$SQLINSTANCEDIR,$SecurityMode -ErrorAction Stop  -Credential $domainCred

            # Install SMA Webplatform installer 5 
            $App = "WAP"
            $Action = "Install WebPlatformInstaller_amd64_en-US.msi"
            Update-VIALog -Data "Action: $Action - $App"
            $ScriptBlock = {
                $Result = Start-Process msiexec.exe -ArgumentList "/i ""D:\WebPlatformInstaller5\WebPlatformInstaller_amd64_en-US.msi"" /qn" -Wait -NoNewWindow -PassThru -Verbose
                $result.ExitCode
            }
            Invoke-Command -VMName $ServerData.VMName -ScriptBlock $ScriptBlock -Credential $domainCred

            #Restart
            Update-VIALog -Data "Restart $($ServerData.VMName)"
            Wait-VIAVMRestart -VMname $($ServerData.VMName) -Credentials $domainCred
            Wait-VIAServiceToRun -VMname $($ServerData.VMName) -Credentials $domainCred
        }
        'WSUS'{
            #Action
            $App = "WSUS Metadata Sync"
            $Action = "Execute"
            Update-VIALog -Data "Action: $Action - $App"
            Invoke-Command -VMName $ServerData.VMName -FilePath C:\Setup\HYDv10\Scripts\Set-VIARole-WSUS-SyncMetaData.ps1 -ErrorAction Stop -Credential $domainCred 
        }
        Default {}
    }
}

#End Custom Actions

##############

#Action
$Action = "Done"
Write-Verbose "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."

#Action
switch ($FinishAction)
{
    'Reboot'{
        $Action = "Restart"
        Write-Verbose "Action: $Action"
        Restart-VIAVM -VMname $($ServerData.VMName)
    }
    'Shutdown'{
        $Action = "Shutdown"
        Write-Verbose "Action: $Action"
        Stop-VM -Name $($ServerData.VMName)
    }
    Default {}
}
