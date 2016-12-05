#Create VM in corp.viamonstra.com
#Set Values

#Import-Modules
$TotalTime = Measure-Command {
    Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
    Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
    Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force
}
$TotalTime.ToString()

#Set Values
$TotalTime = Measure-Command {
    $Servers = "HV01","HV02"
    $VHDImage = "C:\Setup\VHD\WS2016_G2_DataCenter_UI_Fabric.vhdx"
}
$TotalTime.ToString()

#Set Values
$TotalTime = Measure-Command {
    $MountFolder = "C:\MountVHD"
    $AdminPassword = "P@ssw0rd"
    $DomainInstaller = "Administrator"
    $DomainName = "corp.viamonstra.com"
    $DomainAdminPassword = "P@ssw0rd"
    $VMLocation = "D:\VMs\DEMO"
    $VMMemory = 4GB
    $VMSwitchName = "ViaMonstraNAT"
    $localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
    $domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)
    $VIASetupCompletecmdCommand = "cmd.exe /c PowerShell.exe -Command New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name OSDeployment -Value Done -PropertyType String"
    $SetupRoot = "C:\Setup"
}
$TotalTime.ToString()

#Build VMs
$TotalTime = Measure-Command {
    Foreach($Server in $Servers){
        If ((Test-VIAVMExists -VMname $Server) -eq $true){Write-Host "$Server already exist";Break}
        Write-Host "Creating $Server"
        $VM = New-VIAVM -VMName $Server -VMMem $VMMemory -VMvCPU 2 -VMLocation $VMLocation -VHDFile $VHDImage -DiskMode Diff -VMSwitchName $VMSwitchName -VMGeneration 2 -Verbose
        $VIAUnattendXML = New-VIAUnattendXML -Computername $Server -OSDAdapter0IPAddressList DHCP -DomainOrWorkGroup Domain -ProtectYourPC 1 -DNSDomain $DomainName -Verbose
        $VIASetupCompletecmd = New-VIASetupCompleteCMD -Command $VIASetupCompletecmdCommand -Verbose
        $VHDFile = (Get-VMHardDiskDrive -VMName $Server).Path
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
        Get-VM -Name $Server -Verbose
    }
}
$TotalTime.ToString()

#Add datadrives
$TotalTime = Measure-Command {
    Foreach($server in $servers){
        New-VIAVMHarddrive -VMname $Server -NoOfDisks 1 -DiskSize 250GB
    }
}
$TotalTime.ToString()

#Add more memory
$TotalTime = Measure-Command {
    Get-VM -Name $servers | Set-VMMemory -StartupBytes 4096mb -ErrorAction Stop
}
$TotalTime.ToString()

#Deploy them
$TotalTime = Measure-Command {
    foreach($Server in $Servers){
        Write-Host "Working on $Server"
        Start-VM $Server
        Wait-VIAVMIsRunning -VMname $Server
        Wait-VIAVMHaveICLoaded -VMname $Server
        Wait-VIAVMHaveIP -VMname $Server
        Wait-VIAVMDeployment -VMname $Server
    }
}
$TotalTime.ToString()
