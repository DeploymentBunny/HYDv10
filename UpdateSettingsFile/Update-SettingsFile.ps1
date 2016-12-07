Param
(
    [parameter(position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
)


#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force -ErrorAction Stop

#Set Values
$log = "$env:TEMP\$ServerName" + ".log"

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile

#Action
$Action = "Update $SettingsFile"
Write-Output "Action: $Action"
foreach ($AccountName in $Settings.Fabric.DomainAccounts.DomainAccount)
{
    $ReturnData = New-VIARandomPassword -PasswordLength 16 -Complex $true
    $AccountName.PW = $ReturnData
    $Settings.Save($SettingsFile)
}
