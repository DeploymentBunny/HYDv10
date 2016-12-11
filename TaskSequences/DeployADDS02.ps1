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

#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$ServerName = "ADDS02"
$DomainName = "Fabric"
$log = "$env:TEMP\$ServerName" + ".log"

#Read data from XML
Write-Verbose "Reading $SettingsFile"
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

If ((Test-VIAVMExists -VMname $($ServerData.ComputerName)) -eq $true){Write-Host "$($ServerData.ComputerName) already exist";Exit}
Write-Host "Creating $($ServerData.ComputerName)"
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
Get-VMNetworkAdapter -VMName $($ServerData.ComputerName) | Set-VMNetworkAdapter -DeviceNaming On

#Deploy
Write-Host "Working on $($ServerData.ComputerName)"
Start-VM $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMDeployment -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $localCred

#Rename Default NetworkAdapter
Rename-VMNetworkAdapter -VMName $($ServerData.ComputerName) -NewName "NIC01"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Get-NetAdapter | Disable-NetAdapter -Confirm:$false
    Get-NetAdapter | Enable-NetAdapter -Confirm:$false
    $NIC = (Get-NetAdapterAdvancedProperty -Name * | Where-Object -FilterScript {$_.DisplayValue -eq “NIC01”}).Name
    Rename-NetAdapter -Name $NIC -NewName 'NIC01'
} -Credential $domainCred

#Action
$Action = "Add Datadisks"
foreach($obj in $ServerData.DataDisks.DataDisk){
    If($obj.DiskSize -ne 'NA'){
     C:\Setup\HYDv10\Scripts\New-VIADataDisk.ps1 -VMName $($ServerData.ComputerName) -DiskLabel $obj.Name -DiskSize $obj.DiskSize
    }
}

#Action
$Action = "Partion and Format DataDisk(s)"
Write-Verbose "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -FilePath C:\Setup\hydv10\Scripts\Initialize-VIADataDisk.ps1 -ErrorAction Stop -Credential $domainCred -ArgumentList NTFS

#Add role ADDS
$Role = "ADDS"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param(
        $Role
    )
    C:\Setup\HYDv10\Scripts\Invoke-VIAInstallRoles.ps1 -Role $Role
} -Credential $domainCred -ArgumentList $Role

#Add role ADDS
$DomainForestLevel = 'ws2016'
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param(
        $Password,
        $FQDN,
        $NetBiosDomainName,
        $DomainForestLevel,
        $SiteName
    )
    C:\Setup\HYDv10\Scripts\Set-VIARole-ADDS-SDC.ps1 -Password $Password -FQDN $FQDN -NetBiosDomainName $NetBiosDomainName -DomainForestLevel $DomainForestLevel -SiteName $SiteName
} -Credential $domainCred -ArgumentList $DomainData.DomainAdminPassword,$DomainData.DNSDomain,$DomainData.DomainNetBios,$DomainForestLevel,$DomainData.sitename


#Restart
Restart-VIAVM -VMname $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $domainCred

#Check that ADDS is up and running
do{
$result = Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
        Param(
        $ADDSServerName
        )
        Test-Path -Path \\$ADDSServerName\NETLOGON
    } -Credential $domainCred -ArgumentList $($ServerData.ComputerName)
    Write-Host "Waiting for Domain Controller to be operational..."
    Start-Sleep -Seconds 15
}until($result -eq $true)
Write-Host "Waiting for Domain Controller is now operational..."

#Action
$Action = "SET sc.exe config NlaSvc start=delayed-auto"
Write-Output "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    sc.exe config NlaSvc start=delayed-auto
    Restart-Service -Name NlaSvc -Force
} -Credential $domainCred

#Action
$Action = "Configure Client DNS"
Write-Output "Action: $Action"
$ClientDNSServerAddr = "$($Serverdata.Networkadapters.Networkadapter.DNSServer[0]),$($Serverdata.Networkadapters.Networkadapter.DNSServer[1])"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param(
    $ClientDNSServerAddr
    )
    C:\Setup\HYDv10\Scripts\Set-VIAADClientDNSSettings.ps1 -ClientDNSServerAddr $ClientDNSServerAddr
} -ArgumentList $ClientDNSServerAddr -ErrorAction Stop -Credential $domainCred

#Action
$Action = "Install DHCP"
$Role = "DHCP"
Write-Output "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param(
        $Role
    )
    C:\Setup\HYDv10\Scripts\Invoke-VIAInstallRoles.ps1 -Role $Role
} -Credential $domainCred -ArgumentList $Role

#Action
$Action = "Configure DHCP"
$Role = "DHCP"
Write-Output "Action: $Action - $Role"
Invoke-Command -VMName $($ServerData.ComputerName) -FilePath C:\Setup\HYDv10\Scripts\Set-VIARoles.ps1 -ArgumentList $Role -ErrorAction Stop -Credential $domainCred


#Action
$Action = "Configure DHCP"
$Role = "DHCP"
Write-Output "Action: $Action - $Role"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param(
        $PriDHCPServer,
        $SecDHCPServer
    )
    $Scopes = Get-DhcpServerv4Scope -ComputerName $PriDHCPServer
    $Scopes.ScopeId
    Add-DhcpServerv4Failover -ComputerName $PriDHCPServer -Name ($PriDHCPServer + '-' +$SecDHCPServer) -PartnerServer $SecDHCPServer -ScopeId $Scopes.ScopeId -LoadBalancePercent 70 -MaxClientLeadTime 2:00:00 -AutoStateTransition $true -StateSwitchInterval 2:00:00
} -Credential $domainCred -ArgumentList ($Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ ADDS01).computername,($Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ ADDS02).computername


#Action
$Action = "Remove DNS Forwarders"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Get-DnsServerForwarder | Remove-DnsServerForwarder -Force
} -ErrorAction SilentlyContinue -Credential $domainCred

#Action
#$Action = "Configure DHCP..."
#$DHCPSrvCred = 
#Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
#    Param(
#    $DHCPSrvCred
#    )
#    Set-DhcpServerv4DnsSetting -UpdateDnsRRForOlderClients $true 
#    Set-DhcpServerv4DnsSetting -NameProtection $true
#    $DHCPSrvCred = Get-Credential   #  GET "SVC_ADDS_DHCP"  Creds
#    Set-DhcpServerDnsCredential -Credential  
#} -ErrorAction SilentlyContinue -Credential $domainCred -ArgumentList $DHCPSrvCred

#Action
$Action = "Enable Remote Desktop"
Write-Output "Action: $Action"
Invoke-Command -ComputerName $($ServerData.ComputerName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /AR 0} -ErrorAction Stop -Credential $domainCred

#Action
$Action = "Set Remote Destop Security"
Write-Output "Action: $Action"
Invoke-Command -ComputerName $($ServerData.ComputerName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /CS 0} -ErrorAction Stop -Credential $domainCred

#Action
$Action = "Done"
Write-Output "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."

#Action
if($FinishAction -eq 'Shutdown'){
    $Action = "Shutdown"
    Write-Output "Action: $Action"
    Stop-VM -Name $($ServerData.ComputerName)
}
