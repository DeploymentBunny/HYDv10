<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding(DefaultParameterSetName='Param Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$true)]
Param
(
    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataDiskLabel,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Config
)

Write-Output "Configure role for WSUS"
$DataDisk = Get-Volume -FileSystemLabel "$DataDiskLabel"
$DriveLetter = $DataDisk.DriveLetter + ":"
$WSUSLocation = "$DriveLetter\WSUS"
$Setup = 'C:\Program Files\Update Services\Tools\WsusUtil.exe'
$Argument = "PostInstall SQL_INSTANCE_NAME=$ENV:ComputerName\SQLEXPRESS CONTENT_DIR=$WSUSLocation"
Start-Process -FilePath $Setup -ArgumentList $Argument -Wait -NoNewWindow
