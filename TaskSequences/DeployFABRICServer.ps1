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
    $LogPath,

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
    $FinishAction

)

Function Restart-VIAVMAndWait{
    Param(
    $VMname,
    $Credentials
    )
    Restart-VIAVM -VMname $VMname
    Wait-VIAVMIsRunning -VMname $VMname
    Wait-VIAVMHaveICLoaded -VMname $VMname
    Wait-VIAVMHaveIP -VMname $VMname
    Wait-VIAVMHavePSDirect -VMname $VMname -Credentials $Credentials
}
Function Pause-VIAAcript ($Message = "Press any key to continue . . . ") {
    If ($psISE) {
        # The "ReadKey" functionality is not supported in Windows PowerShell ISE.
        $Shell = New-Object -ComObject "WScript.Shell"
        $Button = $Shell.Popup("Click OK to continue.", 0, "Script Paused", 0)
        Return
    }
 
    Write-Host -NoNewline $Message
    $Ignore =
        16,  # Shift (left or right)
        17,  # Ctrl (left or right)
        18,  # Alt (left or right)
        20,  # Caps lock
        91,  # Windows key (left)
        92,  # Windows key (right)
        93,  # Menu key
        144, # Num lock
        145, # Scroll lock
        166, # Back
        167, # Forward
        168, # Refresh
        169, # Stop
        170, # Search
        171, # Favorites
        172, # Start/Home
        173, # Mute
        174, # Volume Down
        175, # Volume Up
        176, # Next Track
        177, # Previous Track
        178, # Stop Media
        179, # Play
        180, # Mail
        181, # Select Media
        182, # Application 1
        183  # Application 2
 
    While ($KeyInfo.VirtualKeyCode -Eq $Null -Or $Ignore -Contains $KeyInfo.VirtualKeyCode) {
        $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    }
 
    Write-Host
}


##############

#Init

#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$ServerName = $Server
$DomainName = "Fabric"
$log = "$env:TEMP\$ServerName" + ".log"
Update-VIALog -Data "Deploying $ServerName in domain $Domain"

#Read data from XML
Update-VIALog -Data "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile
$CustomerData = $Settings.FABRIC.Customers.Customer
$CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
$ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
$NetworksData = $Settings.FABRIC.Networks.Network
$DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName
$NIC001 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property id -EQ -Value NIC01
$NIC001RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC001.ConnectedToNetwork

$MountFolder = "C:\MountVHD"
$AdminPassword = $CommonSettingData.LocalPassword
$DomainInstaller = $DomainData.DomainAdmin
$DomainName = $DomainData.DomainAdminDomain
$DNSDomain = $DomainData.DNSDomain
$DomainAdminPassword = $DomainData.DomainAdminPassword
$VMMemory = [int]$ServerData.Memory * 1024 * 1024
$VMSwitchName = $CommonSettingData.VMSwitchName
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)
$VIASetupCompletecmdCommand = "cmd.exe /c PowerShell.exe -Command New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name OSDeployment -Value Done -PropertyType String"
$SetupRoot = "C:\Setup"


#Init End

##############

#Deploy VM

#Create VM
Update-VIALog -Data "Check if $($ServerData.ComputerName) is already created"
If ((Test-VIAVMExists -VMname $($ServerData.ComputerName)) -eq $true){Write-Host "$($ServerData.ComputerName) already exist";Exit}
Update-VIALog -Data "Creating $($ServerData.ComputerName)"
$VM = New-VIAVM -VMName $($ServerData.ComputerName) -VMMem $VMMemory -VMvCPU 2 -VMLocation $VMLocation -VHDFile $VHDImage -DiskMode Diff -VMSwitchName $VMSwitchName -VMGeneration 2 -Verbose
$VIAUnattendXML = New-VIAUnattendXML -Computername $($ServerData.ComputerName) -OSDAdapter0IPAddressList $NIC001.IPAddress -DomainOrWorkGroup Domain -ProtectYourPC 3 -Verbose -OSDAdapter0Gateways $NIC001RelatedData.Gateway -OSDAdapter0DNS1 $NIC001RelatedData.DNS[0] -OSDAdapter0DNS2 $NIC001RelatedData.DNS[1] -OSDAdapter0SubnetMaskPrefix $NIC001RelatedData.SubNet -OrgName $CustomerData.Name -Fullname $CustomerData.Name -TimeZoneName $CommonSettingData.TimeZoneName -DNSDomain $DomainData.DNSDomain -DomainAdmin $DomainData.DomainAdmin -DomainAdminPassword $DomainData.DomainAdminPassword -DomainAdminDomain $DomainData.DomainAdminDomain
$VIASetupCompletecmd = New-VIASetupCompleteCMD -Command $VIASetupCompletecmdCommand -Verbose
$VHDFile = (Get-VMHardDiskDrive -VMName $($ServerData.ComputerName)).Path
Mount-VIAVHDInFolder -VHDfile $VHDFile -VHDClass UEFI -MountFolder $MountFolder 
New-Item -Path "$MountFolder\Windows\Panther" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Windows\Setup" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Windows\Setup\Scripts" -ItemType Directory -Force | Out-Null
Copy-Item -Path $VIAUnattendXML.FullName -Destination "$MountFolder\Windows\Panther\$($VIAUnattendXML.Name)" -Force
Copy-Item -Path $VIASetupCompletecmd.FullName -Destination "$MountFolder\Windows\Setup\Scripts\$($VIASetupCompletecmd.Name)" -Force
Copy-Item -Path $SetupRoot\functions -Destination $MountFolder\Setup\Functions -Container -Recurse
Copy-Item -Path $SetupRoot\HYDV10 -Destination $MountFolder\Setup\HYDV10 -Container -Recurse
Dismount-VIAVHDInFolder -VHDfile $VHDFile -MountFolder $MountFolder
Remove-Item -Path $VIAUnattendXML.FullName
Remove-Item -Path $VIASetupCompletecmd.FullName

#Enable Device Naming
Update-VIALog -Data "Enable Device Naming"
Get-VMNetworkAdapter -VMName $($ServerData.ComputerName) | Set-VMNetworkAdapter -DeviceNaming On

#Deploy VM
Update-VIALog -Data "Working on $($ServerData.ComputerName)"
Start-VM $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMDeployment -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $localCred

#Rename Default NetworkAdapter
Update-VIALog -Data "Rename Default NetworkAdapter"
Rename-VMNetworkAdapter -VMName $($ServerData.ComputerName) -NewName "NIC01"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Get-NetAdapter | Disable-NetAdapter -Confirm:$false
    Get-NetAdapter | Enable-NetAdapter -Confirm:$false
    $NIC = (Get-NetAdapterAdvancedProperty -Name * | Where-Object -FilterScript {$_.DisplayValue -eq “NIC01”}).Name
    Rename-NetAdapter -Name $NIC -NewName 'NIC01'
} -Credential $domainCred

#Action
Update-VIALog -Data "Add Datadisks"
foreach($obj in $ServerData.DataDisks.DataDisk){
    If($obj.DiskSize -ne 'NA'){
     C:\Setup\HYDv10\Scripts\New-VIADataDisk.ps1 -VMName $($ServerData.ComputerName) -DiskLabel $obj.Name -DiskSize $obj.DiskSize
    }
}

#Action
$Action = "Partion and Format DataDisk(s)"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -FilePath C:\Setup\hydv10\Scripts\Initialize-VIADataDisk.ps1 -ErrorAction Stop -Credential $domainCred -ArgumentList NTFS

#Action
$Action = "Mount Media ISO"
Update-VIALog -Data "Action: $Action"
Set-VMDvdDrive -VMName $($ServerData.ComputerName) -Path D:\HYDV10ISO\HYDV10.iso

#Deploy VM end

##############

#Begin Custom Actions

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
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallReportViewer2008SP1.ps1 -ArgumentList $Source -ErrorAction Stop -Credential $domainCred 

            #Action
            $App = "SQLExpress"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Option = "Normal"
            $SQLSetup = 'D:\SQL 2014 Express SP1\SETUP.EXE'
            $SQLINSTANCENAME = "SQLExpress"
            $SQLINSTANCEDIR = "E:\SQLDB"
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014SP1Express.ps1 -ArgumentList $SQLSetup,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Restart
            Update-VIALog -Data "Restart $($ServerData.ComputerName)"
            Restart-VIAVMAndWait -VMname $($ServerData.ComputerName) -Credentials $domainCred
        }
        Default {}
    }
}

#Add Roles And Features
Foreach($role in $roles){
    #Action
    $Action = "Add Roles And Features"
    Update-VIALog -Data "Action: $Action"
    Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
        Param(
        $Role
        )
        C:\Setup\HYDv10\Scripts\Invoke-VIAInstallRoles.ps1 -Role $ROLE
    } -ArgumentList $ROLE -ErrorAction Stop -Credential $domainCred
}

#Restart
Update-VIALog -Data "Restart $($ServerData.ComputerName)"
Restart-VIAVMAndWait -VMname $($ServerData.ComputerName) -Credentials $domainCred

#Configure Roles And Features
foreach($Role in $Roles){
    #Action
    $Action = "Configure Roles And Features"
    Update-VIALog -Data "Action: $Action - $ROLE"
    switch ($Role)
    {
        'DEPL' {
            $DataDiskLabel = "DataDisk1"
            $RunAsAccount = "Administrator"
            $RunAsAccountPassword = "P@ssw0rd"
            Invoke-Command -VMName $($ServerData.ComputerName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARoles.ps1 -ArgumentList $Role,$DataDiskLabel,$RunAsAccount,$RunAsAccountPassword -ErrorAction Stop -Credential $domainCred
            
            $Action = "Share Applicationroot"
            Update-VIALog -Data "Action: $Action - $ROLE"
            Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
                Param(
                $DataDiskLabel
                )
                $DriveLetter = (Get-Volume -FileSystemLabel $DataDiskLabel).DriveLetter
                $folders = 'ApplicationRoot','MDTBuildLab','MDTProduction'
                Foreach($folder in $folders){
                    New-Item -Path ($DriveLetter + ":\$folder") -ItemType Directory
                    New-SmbShare -Path ($DriveLetter + ":\$folder") -Name $folder -FullAccess Everyone
                }
            } -ArgumentList $DataDiskLabel -Credential $domainCred
        }
        'RDGW'{
            $Group = "Domain Remote Desktop Users"
            $DomainNetBios = $DomainData.DomainNetBios
            $RemoteFQDN = "rdgw." + $DomainData.DNSDomainExternal
            Invoke-Command -VMName $($ServerData.ComputerName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARDGW01Config.ps1 -ArgumentList $Group,$DomainNetBios,$RemoteFQDN -Verbose -Credential $domainCred
        }
        'RRAS'{
            #Add external Network Adapter
            Add-VMNetworkAdapter -VMName $($ServerData.ComputerName) -Name "NIC02" -DeviceNaming On
            $VMNetworkAdapter = Get-VMNetworkAdapter -VMName $($ServerData.ComputerName) -Name "NIC02"
            Set-VMNetworkAdapterVlan -VMName $($ServerData.ComputerName) -VMNetworkAdapterName $VMNetworkAdapter.Name -VlanId $($NetworksData | Where-Object -Property Name -EQ -Value 'Internet').vlan -Access -Passthru
            Connect-VMNetworkAdapter -VMName $($ServerData.ComputerName) -VMNetworkAdapterName $VMNetworkAdapter.Name -SwitchName $VMSwitchName
            Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
                $NIC = (Get-NetAdapterAdvancedProperty -Name * | Where-Object -FilterScript {$_.DisplayValue -eq “NIC02”}).Name
                Rename-NetAdapter -Name $NIC -NewName 'NIC02'
            } -Credential $domainCred
            Start-Sleep -Seconds 30
            
            #Configure the external IP
            $IPAddress = ($ServerData.Networkadapters.Networkadapter | Where-Object -Property id -EQ -Value 'NIC02').IPAddress
            $Internet = $NetworksData | Where-Object -Property Name -EQ -Value 'Internet'

            Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
                Param(
                    $IPaddress,$Subnet,$Gateway
                )
                $NIC = Get-NetAdapter -Name 'NIC02'
                New-NetIPAddress -IPAddress $IPaddress -ifIndex $NIC.ifIndex -DefaultGateway $Gateway -PrefixLength $Subnet
                $NIC

            } -Credential $domainCred -ArgumentList $IPAddress,$Internet.SubNet,$Internet.Gateway

            #Configure NAT rules
            $RDGWIP = ($Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ RDGW01).Networkadapters.Networkadapter.IPAddress
            Invoke-Command -VMName $($ServerData.ComputerName)  -ScriptBlock {
                Param(
                $RDGWIP
            )
            New-NetNat -Name Internet -InternalIPInterfaceAddressPrefix 172.16.0.0/22
            Add-NetNatStaticMapping -NatName Internet -Protocol TCP -ExternalPort 443 -InternalIPAddress $RDGWIP -ExternalIPAddress 0.0.0.0
            } -Credential $domainCred -ArgumentList $RDGWIP
        }
        'WSUS'{
            $DataDiskLabel = "DataDisk1"
            $RunAsAccount = "Administrator"
            $RunAsAccountPassword = "P@ssw0rd"
            Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
                Param(
                $Role,$DataDiskLabel,$RunAsAccount,$RunAsAccountPassword
                )
                C:\Setup\HYDv10\Scripts\Set-VIARoles.ps1 -Role $Role -DataDiskLabel $DataDiskLabel -RunAsAccount $RunAsAccount -RunAsAccountPassword $RunAsAccountPassword
            } -ArgumentList $Role,$DataDiskLabel,$RunAsAccount,$RunAsAccountPassword -ErrorAction Stop -Credential $domainCred
        }
        Default {}
    }
}

#Restart
Update-VIALog -Data "Restart $($ServerData.ComputerName)"
Restart-VIAVMAndWait -VMname $($ServerData.ComputerName) -Credentials $domainCred

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
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallADK.ps1 -ArgumentList $Source,$Configuration -ErrorAction Stop -Credential $domainCred 

            #Action
            $App = "MDT 8443"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\MDT 8443\MicrosoftDeploymentToolkit_x64.msi'
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallMDT.ps1 -ArgumentList $Source -ErrorAction Stop  -Credential $domainCred
        }
        'SCVM'{
            #Action
            $App = "ADK 1607"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\Windows ADK 10 1607\adksetup.exe'
            $Configuration = "SCVM"
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallADK.ps1 -ArgumentList $Source,$Configuration -ErrorAction Stop -Credential $domainCred 

            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLINSTANCENAME = "MSSQLSERVER"
            $SQLINSTANCEDIR = "E:\SQLDB"
            $SQLRole = 'SCVM2016'
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "SCVMM 2016"
            $Action = "Add Service Account to Local Administrators Group"
            Update-VIALog -Data "Action: $Action - $App"
            $LocalGroup = "Administrators"
            $DomainUser = ($Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCVMM').Name
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -ArgumentList $LocalGroup,$DomainUser -ErrorAction Stop  -Credential $domainCred

            #Restart
            $App = "Server"
            $Action = "Restart"
            Update-VIALog -Data "Action: $Action - $App"
            Restart-VIAVMAndWait -VMname $($ServerData.ComputerName) -Credentials $domainCred

            #Action
            $App = "SCVMM 2016"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $ServiceAccount = $Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCVMM'
            $Service01 = $Settings.FABRIC.Services.Service | Where-Object Name -EQ SCVMM2016
            $Source = 'D:\SC 2016 VMM\setup.exe'
            $SCVMRole = 'Full'
            $SCVMMDomain = $DomainName
            $SCVMMSAccount =  $ServiceAccount.Name
            $SCVMMSAccountPW = $ServiceAccount.PW
            $SCVMMProductKey = 'BXH69-M62YX-QQD6R-3GPWX-8WMFY'
            $SCVMMUserName = $CustomerData.Name
            $SCVMMCompanyName = $CustomerData.Name
            $SCVMMBitsTcpPort = $Service01.SCVMMBitsTcpPort
            $SCVMMVmmServiceLocalAccount = '0'
            $SCVMMTopContainerName = "cn=dkm,"+$DomainData.DomainDS
            $SCVMMLibraryDrive = 'E:'
            Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
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
        'SCOM'{
            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLINSTANCENAME = "MSSQLSERVER"
            $SQLINSTANCEDIR = "E:\SQLDB"
            $SQLRole = 'SCOM2016'
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred
            
            #Restart
            Update-VIALog -Data "Restart $($ServerData.ComputerName)"
            Restart-VIAVMAndWait -VMname $($ServerData.ComputerName) -Credentials $domainCred
            
            #Action
            $App = "SCOM 2016"
            $Action = "Add Service Account to Local Administrators Group"
            Update-VIALog -Data "Action: $Action - $App"
            $LocalGroup = "Administrators"
            $DomainUser = ($Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCOM').Name
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -ArgumentList $LocalGroup,$DomainUser -ErrorAction Stop  -Credential $domainCred

            #Action
            $App = "SCOM 2016 Server"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install OpsMgr Server
            $ServiceAccount = $Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCOM'
            $ActionAccount = $Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Action Account for SCOM'
            $Service01 = $Settings.FABRIC.Services.Service | Where-Object Name -EQ SCOM2016
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMServer'
            Invoke-Command -VMName $($ServerData.ComputerName) -Scriptblock{
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
                Write-Host "Using: $Source $SCOMRole $ManagementGroupName $SqlServerInstance $DWSqlServerInstance $DatareaderUser $DatareaderPassword $ActionAccountUser $ActionAccountPassword"
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -ManagementGroupName $ManagementGroupName -SqlServerInstance $SqlServerInstance -DWSqlServerInstance $DWSqlServerInstance -DatareaderUser $DatareaderUser -DatareaderPassword $DatareaderPassword -DataWriterUser $DatareaderUser -DataWriterPassword $DatareaderPassword -DASAccountUser $DatareaderUser -DASAccountPassword $DatareaderPassword -ActionAccountUser $ActionAccountUser -ActionAccountPassword $ActionAccountPassword
            } -ArgumentList $Source,$SCOMRole,$($DomainData.DomainNetBios),$($Service01.SQLINSTANCENAME),$($Service01.SQLINSTANCENAME),$($($DomainData.DomainNetBios)+'\'+$($ServiceAccount.Name)),$($ServiceAccount.PW),$($($DomainData.DomainNetBios)+'\'+$($ActionAccount.Name)),$($ActionAccount.PW) -ErrorAction Stop  -Credential $domainCred

    
            #Action
            $App = "SCOM 2016 Console"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install Console
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMConsole'
            Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
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
            Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
                Param(
                $Source,
                $SCOMRole,
                $ServiceAccountName,
                $ServiceAccountPW,
                $SqlServerInstance
                )
                C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -DataWriterUser $ServiceAccountName -DataWriterPassword $ServiceAccountPW -SRSInstance $SqlServerInstance
            } -ArgumentList $Source,$SCOMRole,$($($DomainData.DomainNetBios)+'\'+$($ServiceAccount.Name)),$($ServiceAccount.PW),$($Service01.SQLINSTANCENAME) -Credential $domainCred 

            #Action
            $App = "SCOM 2016 WebConsole"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            #Install WebConsole
            $Source = 'D:\SC 2016 OM\setup.exe'
            $SCOMRole = 'OMWebConsole'
            Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
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
            Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
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
            $ProductKey = ($Settings.Fabric.ProductKeys.ProductKey | Where-Object -Property Name -EQ -Value ProduktKeySC2016).key
            Update-VIALog -Data "Action: $Action - $App"
            Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
                Param(
                $ProductId
                )
                Import-Module 'C:\Program Files\Microsoft System Center 2016\Operations Manager\Powershell\OperationsManager'
                Set-SCOMLicense -ProductId $ProductId -Confirm:$false -Verbose
                Restart-Service "System Center Management Configuration" -Force
                Restart-Service "System Center Data Access Service" -Force
            } -ArgumentList $ProductKey -Credential $domainCred
        }
        'SCDP'{
            #Action
            $App = "SQL 2014 STD SP1"
            $Action = "Install Application"
            Update-VIALog -Data "Action: $Action - $App"
            $Source = 'D:\SQL 2014 STD SP1\setup.exe'
            $SQLINSTANCENAME = "MSSQLSERVER"
            $SQLINSTANCEDIR = "E:\SQLDB"
            $SQLRole = 'SCDP2016'
            Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

            #Restart
            Update-VIALog -Data "Restart $($ServerData.ComputerName)"
            Restart-VIAVMAndWait -VMname $($ServerData.ComputerName) -Credentials $domainCred
        }
        Default {}
    }
}

#End Custom Actions

##############

#Final steps

#Action
$Action = "Enable Remote Desktop"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /AR 0} -ErrorAction Stop -Credential $domainCred

#Action
$Action = "Set Remote Destop Security"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /CS 0} -ErrorAction Stop -Credential $domainCred

#Restart
Restart-VIAVM -VMname $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $domainCred

#Action
$Action = "Dismount Media ISO"
Write-Verbose "Action: $Action"
#Set-VMDvdDrive -VMName $($ServerData.ComputerName) -Path $null

#Action
$Action = "Done"
Update-VIALog -Data "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."

#Action
if($FinishAction -eq 'Shutdown'){
    $Action = "Shutdown"
    Update-VIALog -Data "Action: $Action"
    Stop-VM -Name $($ServerData.ComputerName)
}

#Final steps end