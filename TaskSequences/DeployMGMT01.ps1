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
$ServerName = "MGMT01"
$DomainName = "Fabric"
$log = "$env:TEMP\$ServerName" + ".log"
$FinishAction = 'Shutdown'

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

If ((Test-VIAVMExists -VMname $($ServerData.ComputerName)) -eq $true){Write-Host "$($ServerData.ComputerName) already exist";Break}
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

#Deploy
Write-Host "Working on $($ServerData.ComputerName)"
Start-VM $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMDeployment -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $localCred

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

#Action
$Action = "Enable Remote Desktop"
Write-Output "Action: $Action"
Invoke-Command -ComputerName $($ServerData.ComputerName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /AR 0} -ErrorAction Stop -Credential $domainCred

#Action
$Action = "Set Remote Destop Security"
Write-Output "Action: $Action"
Invoke-Command -ComputerName $($ServerData.ComputerName) -ScriptBlock {cscript.exe C:\windows\system32\SCregEdit.wsf /CS 0} -ErrorAction Stop -Credential $domainCred

#Restart
Restart-VIAVM -VMname $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $domainCred


#Action
$Action = "Final update"
if($FinishAction -eq 'Shutdown'){
    Stop-VM -Name $($ServerData.ComputerName)
}

#Action
$Action = "Final update"
Write-Output "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."
