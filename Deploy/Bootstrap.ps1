#Bootstrap Script for HYDv10

#Read data from Bootstrap XML
$Global:BootstrapFile = "C:\Setup\HYDv10\Config\Bootstrap_LCHOST.xml"
[xml]$Global:Bootstrap = Get-Content $BootstrapFile -ErrorAction Stop

#Set Vars
$Global:Solution = $Bootstrap.BootStrap.CommonSettings.CommonSetting.Solution
$Global:Logpath = $Bootstrap.BootStrap.CommonSettings.CommonSetting.Logpath

#Enable verbose for testing
#$Global:VerbosePreference = "Continue"
$Global:VerbosePreference = "SilentlyContinue"

#Import-Modules
Import-Module -Global C:\Setup\Functions\VIAHypervModule.psm1
Import-Module -Global C:\Setup\Functions\VIAUtilityModule.psm1
Import-Module -Global C:\Setup\Functions\VIAXMLUtility.psm1
Import-Module -Global C:\Setup\Functions\VIADeployModule.psm1

#Enable verbose for testing
$Global:VerbosePreference = "Continue"
#$Global:VerbosePreference = "SilentlyContinue"

#Verify Access to all active ISOs
Write-Verbose "Checking access to all active ISO images"
foreach($item in ($Bootstrap.BootStrap.ISOs.ISO | Where-Object -Property Active -EQ -Value $true)){
    if((Test-Path -Path $($item.path + '\' + $item.Name)) -eq $false){
        Write-Warning "Could not access $($item.path + '\' + $item.Name)"
    }else{Write-Verbose "Access to $($item.path + '\' + $item.Name) is ok"}
}

#Verify Access to all active folders
Write-Verbose "Checking access to all active folders"
foreach($item in ($Bootstrap.BootStrap.Folders.Folder | Where-Object -Property Active -EQ -Value $true)){
    if((Test-Path -Path $item.path) -eq $false){
        Write-Warning "Could not access $($item.path)"
    }else{Write-Verbose "Access to $($item.path) is ok"}
}

#Verify Access to all HYDv10.ISO folders
Write-Verbose "Checking access to HYDV10.ISO content folders"
foreach($item in ($Bootstrap.BootStrap.ISOFolders.ISOFolder | Where-Object -Property Active -EQ -Value $true)){
    if((Test-Path -Path $item.path) -eq $false){
        Write-Warning "Could not access $($item.path)"
    }else{Write-Verbose "Access to $($item.path) is ok"}
}

#Verify Access to all active VHDs
Write-Verbose "Checking access to all active VHD's"
foreach($item in ($Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property Active -EQ -Value $true)){
    if((Test-Path -Path $($item.Path + "\" + $item.Name)) -eq $false){
        Write-Warning "Could not access $($item.Path + "\" + $item.Name)"
    }else{Write-Verbose "Access to $($item.Path + "\" + $item.Name) is ok"}
}

#Verify Access to all active WIM's
Write-Verbose "Checking access to all active WIM's"
foreach($item in ($Bootstrap.BootStrap.WIMs.WIM | Where-Object -Property Active -EQ -Value $true)){
    if((Test-Path -Path $($item.Path + "\" + $item.Name)) -eq $false){
        Write-Warning "Could not access $($item.Path + "\" + $item.Name)"
    }else{Write-Verbose "Access to $($item.Path + "\" + $item.Name) is ok"}
}

#Create VHD's if needed
Write-Verbose "Create VHD's if needed"
foreach($item in ($Bootstrap.BootStrap.VHDs.VHD | Where-Object -Property Active -EQ -Value $true)){
    $VHDPath = $($item.Path + "\" + $item.Name)
    if((Test-Path -Path $VHDPath) -eq $false){
        Write-Warning "Could not access $VHDPath"
        Write-Warning "Trying to create $VHDPath"
        switch ($item.Source)
        {
            WIM{
            }
            ISO{
                $ISO = ($Bootstrap.BootStrap.ISOs.ISO | Where-Object -Property id -EQ -Value $item.RelatedItem)
                $ISOFile = $ISO.Path + '\' + $iso.Name
                Write-Verbose "Using ISO: $ISOFile "
                $PackagesLocation = ($Bootstrap.BootStrap.Folders.Folder | Where-Object -Property Name -EQ -Value WS2016PackagesFolder).path

                #Check stuff
                if((Test-Path -Path $ISOFile) -ne $True){Write-Warning "No access to $ISOFile";Break}
                if((Test-Path -Path $PackagesLocation) -ne $True){Write-Warning "No access to $PackagesLocation";Break}
                if((Test-Path -Path $VHDPath) -eq $True){Write-Warning "$VHDPath already exist";Break}

                #Verbose Info
                Write-Verbose "Creating $VHDPath using $ISOFile with packges from $PackagesLocation"

                #Get driveletter from media
                $DriveLetter = "$((Mount-DiskImage $ISOFile -PassThru | Get-Volume).DriveLetter):"

                if($item.ui -eq 'NANO'){
                    #Convert the Standard WIMfile to VHDx file for UEFI boot
                    C:\Setup\hydv10\Scripts\Convert-VIAWIM2VHD.ps1 -SourceFile "$DriveLetter\NanoServer\NanoServer.wim" -Disklayout $item.Type -Index $item.Index -DestinationFile $VHDPath -SizeInMB (($Bootstrap.BootStrap.CommonSettings.CommonSetting.VHDSize)/10) -PathtoPackagesFolder $PackagesLocation
                }
                else{
                    #Convert the Standard WIMfile to VHDx file for UEFI boot
                    C:\Setup\hydv10\Scripts\Convert-VIAWIM2VHD.ps1 -SourceFile "$DriveLetter\sources\install.wim" -Disklayout $item.Type -Index $item.Index -DestinationFile $VHDPath -SizeInMB $Bootstrap.BootStrap.CommonSettings.CommonSetting.VHDSize -PathtoPackagesFolder $PackagesLocation -Features NetFx3 -PathtoSXSFolder "$DriveLetter\sources\sxs"
                }

                #Dismount the ISO file
                Dismount-DiskImage $ISOFile
            }
            Default{
            }
        }
    }else{Write-Verbose "$VHDPath already exists"}
}

#Create ISO's if needed
$ISOs = $Bootstrap.BootStrap.ISOs.ISO | Where-Object -Property Custom -EQ -Value $true
foreach($item in $ISOs){
    $ISOFile = $($item.Path + '\' + $item.Name)
    if(((Test-Path -Path $ISOFile)-eq $false)){
        Write-Warning "$ISOFile is missing, trying to create..."
        $SourceFolders = $($Bootstrap.BootStrap.ISOFolders.ISOFolder | Where-Object -Property RelatedItem -EQ -Value $item.id).path
        foreach($item in $SourceFolders){
            Move-Item -Path $item -Destination $(($Bootstrap.BootStrap.Folders.Folder | Where-Object -Property Name -EQ -Value TempISO).path)
            
        }
        New-VIAISOImage -SourceFolder $(($Bootstrap.BootStrap.Folders.Folder | Where-Object -Property Name -EQ -Value TempISO).path) -Destinationfile $ISOFile
        foreach($item in $SourceFolders){
            Move-Item -Path $((($Bootstrap.BootStrap.Folders.Folder | Where-Object -Property Name -EQ -Value TempISO).path) + '\' + $($item | Split-Path -Leaf)) -Destination $($item | Split-Path -Parent)
        }
    }
}
