Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

$SourceFolder = 'C:\Setup\DL'
$DestionationFolder = 'C:\Setup\TempISO'
$ISO = 'D:\HYDV10ISO\HYDV10.iso'

$Folders = @(
'SC 2016 DPM'
'SC 2016 OM'
'SC 2016 OR'
'SC 2016 VMM'
'SQL 2014 Express SP1'
'SQL 2014 STD SP1'
'SQL 2016 STD SP1'
'Windows ADK 10 1607'
'Windows Server 2016'
'Report Viewer 2008 SP1'
'MDT 8443'
)

foreach($Folder in $Folders){
    Move-Item -Path $($SourceFolder + '\' + $Folder) -Destination $($DestionationFolder + '\' + $Folder)
}

New-VIAISOImage -SourceFolder $DestionationFolder -Destinationfile $ISO

foreach($Folder in $Folders){
    Move-Item -Path $($DestionationFolder + '\' + $Folder) -Destination $($SourceFolder + '\' + $Folder)
}
