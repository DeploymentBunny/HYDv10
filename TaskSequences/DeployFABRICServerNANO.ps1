#Step 1:Set Var
$Server = 'VIANANO03'
$VHDImage = "C:\Setup\VHD\WS2016_Datacenter_UEFI_NANO_EVAL_Fabric.vhdx"
$MountFolder = "C:\MountVHD"
$DomainInstaller = "Administrator"
$VMLocation = "D:\VMs"
$VMMemory = 1GB
$adminPassword = "P@ssw0rd"
$domainName = "corp.viamonstra.com"
$domainAdminPassword = "P@ssw0rd"
$localCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$domainCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)
$VIASetupCompletecmdCommand = "cmd.exe /c PowerShell.exe -Command New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name OSDeployment -Value Done -PropertyType String"
$SetupRoot = "C:\Setup"
$PackagesFolderNANO = "E:\NanoServer\Packages"
$DC = "DC01.corp.viamonstra.com"
$BlobFolder = "C:\setup\ws2016lab\Blobs"
$Blob = "$BlobFolder\obj.blob"
$UATemplateSource = "C:\Setup\WS2016LAB\Settings\uatemplate.xml"
$VMSwitchName = "ViaMonstraNAT"

#Import modules
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

If ((Test-VIAVMExists -VMname $Server) -eq $true){Write-Host "$Server already exist";Break}
Write-Host "Creating $Server"
$VM = New-VIAVM -VMName $Server -VMMem $VMMemory -VMvCPU 2 -VMLocation $VMLocation -VHDFile $VHDImage -DiskMode Diff -VMSwitchName $VMSwitchName -VMGeneration 2 -Verbose
$VIASetupCompletecmd = New-VIASetupCompleteCMD -Command $VIASetupCompletecmdCommand -Verbose
$VHDFile = (Get-VMHardDiskDrive -VMName $Server).Path
Mount-VIAVHDInFolder -VHDfile $VHDFile -VHDClass UEFI -MountFolder $MountFolder 
New-Item -Path "$MountFolder\Windows\Panther" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Windows\Setup" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Windows\Setup\Scripts" -ItemType Directory -Force | Out-Null
New-Item -Path "$MountFolder\Temp" -ItemType Directory -Force
Copy-Item -Path $VIASetupCompletecmd.FullName -Destination "$MountFolder\Windows\Setup\Scripts\$($VIASetupCompletecmd.Name)" -Force
Copy-Item -Path $UATemplateSource -Destination "$MountFolder\Windows\Panther\uatemplate.xml" -Force

#Step 6: Create The Blob for Offline Domain Join
Invoke-Command -VMName DEMO-DC01 -Credential $DomainCred -ScriptBlock{
    Param($Server)
    $Blob = "C:\Blobs\obj.blob"
    $BlobFolder = "C:\Blobs"
    if(!(Test-Path $BlobFolder)){New-Item -Path $BlobFolder -ItemType Directory -Force}
    if(Test-Path -Path $Blob){Remove-Item -Path $Blob}
    C:\Windows\System32\djoin.exe /provision /domain corp.viamonstra.com /machine $Server /savefile C:\blobs\obj.blob
} -ArgumentList $Server

#Step 7: Grab the Blob and send to Variable
$BlobData = Invoke-Command -VMName DEMO-DC01 -Credential $DomainCred -ScriptBlock{
    $Blob = "C:\blobs\obj.blob"
    $(Get-Content $Blob)
}

#Step 8: Get the blob from Variable and store on VHD
$BlobData | Out-File -FilePath $Blob -Force
Copy-Item -Path $Blob -Destination "$MountFolder\Temp" -Force -Verbose

#Step 9: Get UATemplate, Update and store on VHD
$UAXMLTemplateFile = "$MountFolder\Windows\Panther\unattend.xml"
(Get-Content $UATemplateSource) -replace ('OSDComputerName',"$Server") | Out-File $UAXMLTemplateFile -Encoding ascii -Force

#Add Roles and Feature Packs
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-BootFromWim-Package.cab" -Path "$MountFolder"  
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-BootFromWim-Package_en-us.cab" -Path "$MountFolder"  
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-Compute-Package.cab" -Path "$MountFolder"
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-Compute-Package_en-us.cab" -Path "$MountFolder"      
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-Containers-Package.cab" -Path "$MountFolder"   
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-Containers-Package_en-us.cab" -Path "$MountFolder"   
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-DCB-Package.cab" -Path "$MountFolder"          
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-DCB-Package_en-us.cab" -Path "$MountFolder"          
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-Defender-Package.cab" -Path "$MountFolder"     
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-Defender-Package_en-us.cab" -Path "$MountFolder"     
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-DNS-Package.cab" -Path "$MountFolder"          
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-DNS-Package_en-us.cab" -Path "$MountFolder"          
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-DSC-Package.cab" -Path "$MountFolder"          
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-DSC-Package_en-us.cab" -Path "$MountFolder"          
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path "$MountFolder"
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-FailoverCluster-Package_en-us.cab" -Path "$MountFolder"
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-Guest-Package.cab" -Path "$MountFolder"        
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-Guest-Package_en-us.cab" -Path "$MountFolder"        
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-Host-Package.cab" -Path "$MountFolder"         
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-Host-Package_en-us.cab" -Path "$MountFolder"         
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-IIS-Package.cab" -Path "$MountFolder"          
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-IIS-Package_en-us.cab" -Path "$MountFolder"          
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-NPDS-Package.cab" -Path "$MountFolder"         
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-NPDS-Package_en-us.cab" -Path "$MountFolder"         
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-OEM-Drivers-Package.cab" -Path "$MountFolder"  
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-OEM-Drivers-Package_en-us.cab" -Path "$MountFolder"  
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-SCVMM-Compute-Package.cab" -Path "$MountFolder"
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-SCVMM-Compute-Package_en-us.cab" -Path "$MountFolder"
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-SCVMM-Package.cab" -Path "$MountFolder"        
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-SCVMM-Package_en-us.cab" -Path "$MountFolder"        
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-SecureStartup-Package.cab" -Path "$MountFolder"
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-SecureStartup-Package_en-us.cab" -Path "$MountFolder"
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-ShieldedVM-Package.cab" -Path "$MountFolder"   
#Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-ShieldedVM-Package_en-us.cab" -Path "$MountFolder"   
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\Microsoft-NanoServer-Storage-Package.cab" -Path "$MountFolder"
Add-WindowsPackage -PackagePath "$PackagesFolderNANO\en-us\Microsoft-NanoServer-Storage-Package_en-us.cab" -Path "$MountFolder"

Dismount-VIAVHDInFolder -VHDfile $VHDFile -MountFolder $MountFolder
Remove-Item -Path $VIASetupCompletecmd.FullName
Get-VM -Name $Server -Verbose

Write-Host "Working on $Server"
Start-VM $Server
Wait-VIAVMIsRunning -VMname $Server -Verbose
Wait-VIAVMHaveICLoaded -VMname $Server -Verbose
Wait-VIAVMHaveIP -VMname $Server -Verbose
Wait-VIAVMDeployment -VMname $Server -Verbose
Wait-VIAVMHavePSDirect -VMname $Server -Credentials $localCred -Verbose
Get-VM -Name $Server

Invoke-Command -VMName $Server -Credential $localCred -ScriptBlock{
    djoin /requestodj /loadfile c:\temp\obj.blob /windowspath c:\windows /localos
}

Write-Host "Working on $Server"
Stop-VM -Name $Server -Passthru | Start-VM
Wait-VIAVMIsRunning -VMname $Server
Wait-VIAVMHaveICLoaded -VMname $Server
Wait-VIAVMHaveIP -VMname $Server
Get-VM -Name $Server
