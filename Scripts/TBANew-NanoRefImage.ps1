#Mount C:\Setup\ISO\Windows Server 2016.iso
$WimFile = "C:\NanoServer\NanoServer.wim"
$VHDXFile = "C:\Setup\WS2016lab\VHD\WS2016N_UEFI.vhdx"
C:\Setup\ws2016lab\Scripts\Convert-VIAWIM2VHD.ps1 -SourceFile $WimFile -DestinationFile $VHDXFile -Disklayout UEFI -Index 1 -SizeInMB 5000 -Verbose

#Add Package to VHD
Mount-DiskImage -ImagePath $VHDXFile
$DriveLetter = (Get-Volume | Where-Object -Property FileSystemLabel -EQ -Value OSDisk).DriveLetter
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-Storage-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-Storage-Package_en-us.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-Guest-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-Guest-Package_en-us.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-FailoverCluster-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-FailoverCluster-Package_en-us.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-Compute-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-Compute-Package_en-us.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-Host-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-Host-Package_en-us.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-SCVMM-Compute-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-SCVMM-Compute-Package_en-us.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\Microsoft-NanoServer-SCVMM-Package.cab" -Path "$($DriveLetter):\"
Add-WindowsPackage -PackagePath "C:\NanoServer\Packages\en-us\Microsoft-NanoServer-SCVMM-Package_en-us.cab" -Path "$($DriveLetter):\"

#Get all patches and update the VHDx
$Patches = Get-ChildItem -Path "C:\Setup\WS2016LAB\hotfix" -Recurse -File
foreach($Patch in $Patches){
    Add-WindowsPackage -PackagePath $Patch.FullName -Path "$($DriveLetter):"
}

Dismount-DiskImage -ImagePath $VHDXFile
