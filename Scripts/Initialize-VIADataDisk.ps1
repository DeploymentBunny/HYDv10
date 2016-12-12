<#
#>
Param(
    [parameter(position=0,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('NTFS','ReFS')]
    $FileSystem
)

$Disks = Get-Disk | Where-Object -Property OperationalStatus -like -Value Offline
foreach($Disk in $Disks)
{
    $DiskNumber = $Disk.Number
    Write-Verbose "Working on $($DiskNumber|%{"{0:D2}" -f $_})"
    Initialize-Disk -Number $DiskNumber –PartitionStyle GPT
    $Drive = New-Partition -DiskNumber $DiskNumber -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' -UseMaximumSize
    $Drive | Format-Volume -FileSystem $FileSystem -NewFileSystemLabel "DataDisk$($DiskNumber|%{"{0:D2}" -f $_})" -Confirm:$false
    Add-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $Drive.PartitionNumber -AssignDriveLetter
    $Drive = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $Drive.PartitionNumber
    $Volume = $Drive.DriveLetter
    $DriveLetter
}
