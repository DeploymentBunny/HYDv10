$ISOFile = 'C:\Setup\ISO\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-2_MLF_X21-22843.ISO'
$PackagesLocation = "C:\Setup\Packages\WS2016"
$VHDLocation = "C:\Setup\VHDTest"
[XML]$Data = Get-Content -Path C:\Setup\HYDv10\CreateRefImagesFromISO\Create-VIARefImagesFromISO.xml

#Mount the ISO and get the driveletter
$mountResult = Mount-DiskImage $ISOFile -PassThru
$ISODrive = ($mountResult | Get-Volume).DriveLetter

#Get the WimFile
$Wimfile = "$($ISODrive):\sources\install.wim"
#Get-WindowsImage -ImagePath $Wimfile

foreach($Item in ($Data.Items.Item)){
    #Convert the Standard WIMfile to VHDx file for UEFI boot
    $VHDXFile = "$($VHDLocation)\$($Item.name)"
    C:\Setup\hydv10\Scripts\Convert-VIAWIM2VHD.ps1 -SourceFile $Wimfile -Disklayout $Item.Disklayout -Index $item.Index -DestinationFile $VHDXFile -SizeInMB 80000

    #Add NET 2/3 from Source
    Add-WindowsFeature -Name Net-Framework-Core -IncludeAllSubFeature -IncludeManagementTools -Source "$($ISODrive):\sources\SXS" -Vhd $VHDXFile
    Start-Sleep -Seconds 15

    #Mount VHDx and get the driveletter
    $mountResult = Mount-DiskImage $VHDXFile -PassThru
    $VHDDisk = Get-DiskImage -ImagePath $mountResult.ImagePath | Get-Disk
    $VHDDrive = Get-Partition -DiskNumber $VHDDisk.Number | Where-Object -Property type -EQ Basic

    #Get all patches and update the VHDx
    $Patches = Get-ChildItem -Path $PackagesLocation -Recurse -File
    foreach($Patch in $Patches){
        Add-WindowsPackage -PackagePath $Patch.FullName -Path "$($VHDDrive.DriveLetter):"
    }

    #Check if the patches has been installed
    Get-WindowsPackage -Path "$($VHDDrive.DriveLetter):"

    #Dismount the VHDX file
    Dismount-DiskImage $VHDXFile
}

#Dismount the ISO file
Dismount-DiskImage $mountResult
