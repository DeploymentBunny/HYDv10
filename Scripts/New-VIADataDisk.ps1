<#
.Synopsis
    Script used to Deploy and Configure FILE01
.DESCRIPTION
    Created: 2015-02-21
    Version: 1.0
    Author : Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com
    Disclaimer: This script is provided "AS IS" with no warranties.
.EXAMPLE
    C:\Setup\RunTimes\Install-File01.ps1 -WIM C:\Setup\WIM\REFWS2012R2-001.wim -SettingsFile C:\Setup\Scripts\FASettings.xml
#>

[cmdletbinding(SupportsShouldProcess=$True)]

Param
(
    [parameter(position=0,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    #[ValidateRange(1-10)]
    $VMName,

    [parameter(position=1,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    #[ValidateRange(1-10)]
    $DiskLabel,

    [parameter(position=2,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    #[ValidateRange(20GB-500GB)]
    $DiskSize
)

$Diskpath = (Get-VMHardDiskDrive -VMName $VMName | Select-Object -First 1).path | Split-Path -Parent
$NewDisk = ($Diskpath + "\" + $DiskLabel+'.vhdx')
if((Test-Path -Path $NewDisk) -eq $True){Write-Warning "Disk $NewDisk already exists...";Break}
$DataDiskToAdd = New-VHD -Path $NewDisk -Dynamic -SizeBytes ([int]$DiskSize * 1024 * 1024 * 1024) -ErrorAction Stop
Add-VMHardDiskDrive -Path $DataDiskToAdd.Path -VMName $VMName -ErrorAction Stop
