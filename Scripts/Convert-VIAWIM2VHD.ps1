Param(
    [Parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $SourceFile,

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DestinationFile,

    [parameter(mandatory=$False)]
    [ValidateSet("BIOS","UEFI","COMBO")]
    [String]
    $Disklayout = "UEFI",

    [parameter(mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Index = "1",

    [parameter(mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $SizeInMB = "80000",

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [Switch]
    $SXSFolderCopy,

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $PathtoSXSFolder = 'NA',

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $PathtoExtraFolder = 'NA',

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $PathtoPatchFolder = 'NA',

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $PathtoPackagesFolder = 'NA',

    [Parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [Array]
    $Features,

    [parameter(mandatory=$False)]
    [ValidateSet("w7","w2k8r2")]
    [String]
    $OSVersion,

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DISMExe = "dism.exe"
)
Function Invoke-Exe{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,

        [parameter(mandatory=$true,position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Arguments,

        [parameter(mandatory=$false,position=2)]
        [ValidateNotNullOrEmpty()]
        [int]
        $SuccessfulReturnCode = 0
    )

    Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
    $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru

    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"

    if(!($ReturnFromEXE.ExitCode -eq $SuccessfulReturnCode)) {
        throw "$Executable failed with code $($ReturnFromEXE.ExitCode)"
    }
}
Function New-FAVHD{
    [CmdletBinding(SupportsShouldProcess=$true)]

    Param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VHDFile,

    [Parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VHDSizeinMB,

    [Parameter(Position=2)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('EXPANDABLE','FIXED')]
    [string]
    $VHDType
    )

    if(!(Test-Path -Path ($VHDFile | Split-Path -Parent))){
        throw "Folder does not exists..."}
    
    #Check if file exists
    if(Test-Path -Path $VHDFile){
        throw "File exists..."}

    $diskpartcmd = New-Item -Path $env:TEMP\diskpartcmd.txt -ItemType File -Force
    Set-Content -Path $diskpartcmd -Value "CREATE VDISK FILE=""$VHDFile"" MAXIMUM=$VHDSizeinMB TYPE=$VHDType"
    $Exe = "DiskPart.exe"
    $Args = "-s $($diskpartcmd.FullName)"
    Invoke-Exe -Executable $Exe -Arguments $Args -SuccessfulReturnCode 0
    Remove-Item $diskpartcmd -Force -ErrorAction SilentlyContinue
}

#Testing all path's
if((Test-Path -Path $DestinationFile) -eq $True){Write-Warning "$DestinationFile already exists";BREAK}
if((Test-Path -Path $SourceFile) -eq $false){Write-Warning "No access to $SourceFile";BREAK}

If($SXSFolderCopy -eq $True){
    if((Test-Path -Path $PathtoSXSFolder) -eq $false){Write-Warning "Unable to access $PathtoSXSFolder";BREAK}else{Write-verbose "Access to $PathtoSXSFolder is ok"}
}

If($PathtoExtraFolder -ne 'NA'){
    if((Test-Path -Path $PathtoExtraFolder) -eq $false){Write-Warning "Unable to access $PathtoExtraFolder";BREAK}else{Write-verbose "Access to $PathtoExtraFolder is ok"}
}

If($PathtoPatchFolder -ne 'NA'){
    if((Test-Path -Path $PathtoPatchFolder) -eq $false){Write-Warning "Unable to access $PathtoPatchFolder";BREAK}else{Write-verbose "Access to $PathtoPatchFolder is ok"}
}

If($PathtoPackagesFolder -ne 'NA'){
    if((Test-Path -Path $PathtoPackagesFolder) -eq $false){Write-Warning "Unable to access $PathtoPackagesFolder";BREAK}else{Write-verbose "Access to $PathtoPackagesFolder is ok"}
}

#Apply WIM to VHD(x)
Write-Verbose "Disklayout is set to $Disklayout"
Switch ($Disklayout){
    BIOS{
        Write-Verbose "Disklayout is set to $Disklayout"
        $VHDFile = $DestinationFile
        New-FAVHD -VHDFile $VHDFile -VHDSizeinMB $SizeinMB -VHDType EXPANDABLE
        Mount-DiskImage -ImagePath $VHDFile
        $VHDDisk = Get-DiskImage -ImagePath $VHDFile | Get-Disk
        $VHDDiskNumber = [string]$VHDDisk.Number
        Write-Verbose "Disknumber is now $VHDDiskNumber"

        # Format VHDx
        Initialize-Disk -Number $VHDDiskNumber -PartitionStyle MBR
        Write-Verbose "Initialize disk as MBR"
        $VHDDrive = New-Partition -DiskNumber $VHDDiskNumber -UseMaximumSize -IsActive
        $VHDDrive | Format-Volume -FileSystem NTFS -NewFileSystemLabel OSDisk -Confirm:$false
        Add-PartitionAccessPath -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive.PartitionNumber -AssignDriveLetter
        $VHDDrive = Get-Partition -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive.PartitionNumber
        $VHDVolume = [string]$VHDDrive.DriveLetter+":"
        Write-Verbose "OSDrive Driveletter is now = $VHDVolume"
        $VHDVolumeBoot = [string]$VHDDrive.DriveLetter+":"
        Write-Verbose "OSBoot Driveletter is now = $VHDVolumeBoot"

        #Apply Image
        sleep 5
        $Exe = $DISMExe
        $Args = " /apply-Image /ImageFile:$SourceFile /index:$Index /ApplyDir:$VHDVolume\"
        Invoke-Exe -Executable $Exe -Arguments $Args -SuccessfulReturnCode 0 -Verbose
    }
    UEFI{
        $VHDFile = $DestinationFile
        New-FAVHD -VHDFile $VHDFile -VHDSizeinMB $SizeinMB -VHDType EXPANDABLE
        Mount-DiskImage -ImagePath $VHDFile
        $VHDDisk = Get-DiskImage -ImagePath $VHDFile | Get-Disk
        $VHDDiskNumber = [string]$VHDDisk.Number
        Write-Verbose "Disknumber is now $VHDDiskNumber"

        # Format VHDx
        Initialize-Disk -Number $VHDDiskNumber –PartitionStyle GPT
        $VHDDrive1 = New-Partition -DiskNumber $VHDDiskNumber -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -Size 499MB 
        $VHDDrive1 | Format-Volume -FileSystem FAT32 -NewFileSystemLabel System -Confirm:$false -Verbose
        $VHDDrive2 = New-Partition -DiskNumber $VHDDiskNumber -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -Size 128MB
        $VHDDrive3 = New-Partition -DiskNumber $VHDDiskNumber -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -UseMaximumSize
        $VHDDrive3 | Format-Volume -FileSystem NTFS -NewFileSystemLabel OSDisk -Confirm:$false
        Add-PartitionAccessPath -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive1.PartitionNumber -AssignDriveLetter
        $VHDDrive1 = Get-Partition -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive1.PartitionNumber
        Add-PartitionAccessPath -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive3.PartitionNumber -AssignDriveLetter
        $VHDDrive3 = Get-Partition -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive3.PartitionNumber
        $VHDVolume = [string]$VHDDrive3.DriveLetter+":"
        Write-Verbose "OSDrive Driveletter is now = $VHDVolume"
        $VHDVolumeBoot = [string]$VHDDrive1.DriveLetter+":"
        Write-Verbose "OSBoot Driveletter is now = $VHDVolumeBoot"

        #Apply Image
        sleep 5
        $Exe = $DISMExe
        $Args = " /apply-Image /ImageFile:$SourceFile /index:$Index /ApplyDir:$VHDVolume\"
        Invoke-Exe -Executable $Exe -Arguments $Args -SuccessfulReturnCode 0 -Verbose
    }
    COMBO{
        $VHDFile = $DestinationFile
        New-FAVHD -VHDFile $VHDFile -VHDSizeinMB $SizeinMB -VHDType EXPANDABLE
        Mount-DiskImage -ImagePath $VHDFile
        $VHDDisk = Get-DiskImage -ImagePath $VHDFile | Get-Disk
        $VHDDiskNumber = [string]$VHDDisk.Number
        Write-Verbose "Disknumber is now $VHDDiskNumber"

        # Format VHDx
        Initialize-Disk -Number $VHDDiskNumber -PartitionStyle MBR
        Write-Verbose "Initialize disk as MBR"
        $VHDDrive1 = New-Partition -DiskNumber $VHDDiskNumber -Size 499MB -IsActive
        $VHDDrive1 | Format-Volume -FileSystem FAT32 -NewFileSystemLabel BootDisk -Confirm:$false
        $VHDDrive3 = New-Partition -DiskNumber $VHDDiskNumber -UseMaximumSize
        $VHDDrive3 | Format-Volume -FileSystem NTFS -NewFileSystemLabel OSDisk -Confirm:$false
        Add-PartitionAccessPath -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive1.PartitionNumber -AssignDriveLetter
        $VHDDrive1 = Get-Partition -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive1.PartitionNumber
        Add-PartitionAccessPath -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive3.PartitionNumber -AssignDriveLetter
        $VHDDrive3 = Get-Partition -DiskNumber $VHDDiskNumber -PartitionNumber $VHDDrive3.PartitionNumber
        $VHDVolume = [string]$VHDDrive3.DriveLetter+":"
        $VHDVolumeBoot = [string]$VHDDrive1.DriveLetter+":"
        Write-Verbose "OSDrive Driveletter is now = $VHDVolume"

        #Apply Image
        sleep 5
        $Exe = $DISMExe
        $Args = " /apply-Image /ImageFile:$SourceFile /index:$Index /ApplyDir:$VHDVolume\"
        Invoke-Exe -Executable $Exe -Arguments $Args -SuccessfulReturnCode 0 -Verbose    }
}

#Apply BCD to VHD(x)
Switch ($Disklayout){
    BIOS{
        Switch ($OSVersion){
            W7{
                # Apply BootFiles
                $Exe = "bcdboot"
                $Args = "$VHDVolume\Windows /s $VHDVolume"
                Invoke-Exe -Executable $Exe -Arguments $Args
            }
            WS2K8R2{
                # Apply BootFiles
                $Exe = "bcdboot.exe"
                $Args = "$VHDVolume\Windows /s $VHDVolume"
                Invoke-Exe -Executable $Exe -Arguments $Args
            }
            Default{
                # Apply BootFiles
                Write-Verbose "Creating the BCD"
                $Exe = "bcdboot.exe"
                $Args = "$VHDVolume\Windows /s $VHDVolume /f BIOS"
                Invoke-Exe -Executable $Exe -Arguments $Args

                Write-Verbose "Fixing the BCD store on $($VHDVolumeBoot) for VMM"
                $Exe = "bcdedit.exe"
                $Args = "/store $($VHDVolumeBoot)boot\bcd /set `{bootmgr`} device locate"
                Invoke-Exe -Executable $Exe -Arguments $Args
                
                $Exe = "bcdedit.exe"
                $Args = "/store $($VHDVolumeBoot)boot\bcd /set `{default`} device locate"
                Invoke-Exe -Executable $Exe -Arguments $Args

                $Exe = "bcdedit.exe"
                $Args = "/store $($VHDVolumeBoot)boot\bcd /set `{default`} osdevice locate"
                Invoke-Exe -Executable $Exe -Arguments $Args
            }
        }
    }
    UEFI{
        # Apply BootFiles
        $Exe = "bcdboot"
        $Args = "$VHDVolume\Windows /s $VHDVolumeBoot /f UEFI"
        Invoke-Exe -Executable $Exe -Arguments $Args

        # Change ID on FAT32 Partition, since we cannot assign the correct ID at creationtime depending on a "feature" in Windows
        $DiskPartTextFile = New-Item "diskpart.txt" -type File -Force
        Set-Content $DiskPartTextFile "select disk $VHDDiskNumber"
        Add-Content $DiskPartTextFile "Select Partition 2" -Verbose
        Add-Content $DiskPartTextFile "Set ID=c12a7328-f81f-11d2-ba4b-00a0c93ec93b OVERRIDE"
        Add-Content $DiskPartTextFile "GPT Attributes=0x8000000000000000"
        $DiskPartTextFile
        $Exe = "diskpart.exe"
        $Args = "/s $DiskPartTextFile"
        Invoke-Exe -Executable $Exe -Arguments $Args
    }
    COMBO{
        # Apply BootFiles
        Write-Verbose "Creating the BCD"
        $Exe = "bcdboot.exe"
        $Args = "$VHDVolume\Windows /s $VHDVolumeBoot /f ALL"
        Invoke-Exe -Executable $Exe -Arguments $Args
        
        Write-Verbose "Fixing the BCD store on $($VHDVolumeBoot) for VMM"
        $Exe = "bcdedit.exe"
        $Args = "/store $($VHDVolumeBoot)boot\bcd /set `{bootmgr`} device locate"
        Invoke-Exe -Executable $Exe -Arguments $Args
                
        $Exe = "bcdedit.exe"
        $Args = "/store $($VHDVolumeBoot)boot\bcd /set `{default`} device locate"
        Invoke-Exe -Executable $Exe -Arguments $Args

        $Exe = "bcdedit.exe"
        $Args = "/store $($VHDVolumeBoot)boot\bcd /set `{default`} osdevice locate"
        Invoke-Exe -Executable $Exe -Arguments $Args
    }
}

#Copy SXS Folders to VHD(X)
If($SXSFolderCopy -eq $True){
    Write-Verbose "Execute Copy-Item $PathtoSXSFolder $VHDVolume\Sources\SXS -Force -Recurse"
    Copy-Item $PathtoSXSFolder $VHDVolume\Sources\SXS -Force -Recurse
}

#Apply patches to VHD(X) 
If ($PathtoPatchFolder -NE 'NA'){
    $items = Get-ChildItem -Path $PathtoPatchFolder -Recurse
    foreach($item in $items){
        Add-WindowsPackage -PackagePath $item.FullName -Path $VHDVolume
    }
}
 
#Copy Extra Folders to VHD(X) 
If ($PathtoExtraFolder -NE 'NA'){
    Write-Verbose "Execute Copy-Item $PathtoExtraFolder $VHDVolume\Extra -Force -Recurse"
    Copy-Item $PathtoExtraFolder $VHDVolume\Extra -Force -Recurse
}

#Enable features 
If($Features){
    Foreach($Item in $Features){
        Enable-WindowsOptionalFeature -FeatureName $Item -Source $PathtoSXSFolder -Path $VHDVolume -All
    }
}

#Apply packges to VHD(X) 
If ($PathtoPackagesFolder -NE 'NA'){
    $Items = Get-Childitem -Path $PathtoPackagesFolder
    foreach ($Items in $Packges){
        Add-WindowsPackage –PackagePath $Items.Fullname –Path $VHDVolume
    }
}

#Dismount VHDX
Dismount-DiskImage -ImagePath $VHDFile
Return $VHDFile
