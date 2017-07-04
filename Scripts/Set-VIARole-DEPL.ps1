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
    $RunAsAccount,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccountPassword
)

Write-Output "Configure role for DEPL"
$DataDisk = Get-Volume -FileSystemLabel "$DataDiskLabel" -ErrorAction Stop
$DriveLetter = $DataDisk.DriveLetter + ":"
$RunAsAccountDomain = $env:USERDOMAIN

$TaskName = "FooBar"
$Command = """wdsutil.exe /Initialize-Server /REMINST:""$DriveLetter\RemoteInstall"" /Authorize"""
SCHTASKS /Create /RU $RunAsAccountDomain\$RunAsAccount /RP $RunAsAccountPassword /SC WEEKLY /TN $TaskName /TR $Command /RL HIGHEST /F
Get-ScheduledTask -TaskName $TaskName | Start-ScheduledTask
Start-Sleep 60
Get-ScheduledTask -TaskName $TaskName | Unregister-ScheduledTask -Confirm:$false

$TaskName = "FooBar"
$Command = """wdsutil.exe /Set-Server /AnswerClients:All"""
SCHTASKS /Create /RU $RunAsAccountDomain\$RunAsAccount /RP $RunAsAccountPassword /SC WEEKLY /TN $TaskName /TR $Command /RL HIGHEST /F
Get-ScheduledTask -TaskName $TaskName | Start-ScheduledTask
Start-Sleep 60
Get-ScheduledTask -TaskName $TaskName | Unregister-ScheduledTask -Confirm:$false

Get-Service -Name WDSServer | Start-Service
