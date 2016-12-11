Param
(
    [parameter(position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
)



#Import Modules
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force -ErrorAction Stop

#Set Values
$Global:Solution = "HYDv10"
$Global:Log = "$env:TEMP\HYDv10" + ".log"

#Read data from XML
Update-VIALog -Data "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile

#Check if update is needed
Update-VIALog -Data "Check if update is needed"

if(($Settings.FABRIC.CommonSettings.CommonSetting.PasswordUpdated) -eq $false){
    #Action
    $Action = "Updating $SettingsFile with new passwords"
    Update-VIALog -Data "Action: $Action"
    foreach ($AccountName in $Settings.Fabric.DomainAccounts.DomainAccount)
    {
        $ReturnData = New-VIARandomPassword -PasswordLength 16 -Complex $true
        $AccountName.PW = $ReturnData
        $Settings.Save($SettingsFile)
    }
    
    #Action
    $Action = "Flag $SettingsFile as updated"
    Update-VIALog -Data "Action: $Action"
    ($Settings.FABRIC.CommonSettings.CommonSetting).PasswordUpdated = 'True'
    $Settings.Save($SettingsFile)

}

#Read data from XML
Update-VIALog -Data "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile


if(($Settings.FABRIC.CommonSettings.CommonSetting.PasswordUpdated) -eq $true){
    #Action
    $Action = "$SettingsFile is already updated"
    Update-VIALog -Data "Action: $Action"

    if((Get-ItemProperty -Path $SettingsFile -Name IsReadOnly).IsReadOnly -eq $false){
        #Action
        $Action = "Set $SettingsFile as read-only"
        Update-VIALog -Data "Action: $Action"
        Set-ItemProperty -Path $SettingsFile -Name IsReadOnly -Value $true
    }
}

