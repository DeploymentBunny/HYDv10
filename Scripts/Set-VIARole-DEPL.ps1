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
    [parameter(mandatory=$True,ValueFromPipelineByPropertyName=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    $Role,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DataDiskLabel,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccount,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccountPassword
)

switch ($Role)
{    
    DHCP
    {
        #Action
        $Action = "Authorize the DHCP Server"
        Write-Output "Action: $Action"
        Add-DhcpServerInDC
        Start-Sleep 2

        #Action
        $Action = "Add Security Groups"
        Write-Output "Action: $Action"
        Add-DhcpServerSecurityGroup
        Start-Sleep 2

        #Action
        $Action = "Making the ServerManager happy (Flag DHCP as configured)"
        Write-Output "Action: $Action"
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2 -Force
        Start-Sleep 2

        #Action
        $Action = "Restart Service"
        Write-Output "Action: $Action"
        Restart-Service "DHCP Server" -Force
        Start-Sleep 2
    }
    DEPL
    {
        Write-Output "Configure role for $Role"
        $DataDisk = Get-Volume -FileSystemLabel "$DataDiskLabel"
        $DriveLetter = $DataDisk.DriveLetter + ":"
        $RunAsAccountDomain = $env:USERDOMAIN

        $TaskName = "FooBar"
        $Command = """wdsutil.exe /Initialize-Server /REMINST:""$DriveLetter\RemoteInstall"" /Authorize"""
        SCHTASKS /Create /RU $RunAsAccountDomain\$RunAsAccount /RP $RunAsAccountPassword /SC WEEKLY /TN $TaskName /TR $Command /RL HIGHEST /F
        Get-ScheduledTask -TaskName $TaskName | Start-ScheduledTask
        Start-Sleep 30
        Get-ScheduledTask -TaskName $TaskName | Unregister-ScheduledTask -Confirm:$false

        $TaskName = "FooBar"
        $Command = """wdsutil.exe /Set-Server /AnswerClients:All"""
        SCHTASKS /Create /RU $RunAsAccountDomain\$RunAsAccount /RP $RunAsAccountPassword /SC WEEKLY /TN $TaskName /TR $Command /RL HIGHEST /F
        Get-ScheduledTask -TaskName $TaskName | Start-ScheduledTask
        Start-Sleep 30
        Get-ScheduledTask -TaskName $TaskName | Unregister-ScheduledTask -Confirm:$false

        Get-Service -Name WDSServer | Start-Service
    }
    ADCA
    {
        #Action
        $Action = "Create Credentials"
        Write-Output "Action: $Action"
        $SecurePassword = $RunAsAccountPassword | ConvertTo-SecureString -AsPlainText -Force
        $AdministratorName = $RunAsAccount
        $LogonDomain = $env:USERDOMAIN
        $UserName = "$LogonDomain\$AdministratorName"
        
        $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName,$SecurePassword

        Write-Output "Configure role for $Role"
        Install-AdcsCertificationAuthority `
        -CAType "EnterpriseRootCA" -HashAlgorithmName SHA256 -KeyLength 2048 -ValidityPeriod Years `
        -ValidityPeriodUnits 5 -CACommonName "Fabric-root-CA" -OverwriteExistingCAinDS `
        -OverwriteExistingKey `
        -OverwriteExistingDatabase `
        -Force -Verbose -Credential $Credentials
    }
    WSUS
    {
        Write-Output "Configure role for $Role"
        $DataDisk = Get-Volume -FileSystemLabel "$DataDiskLabel"
        $DriveLetter = $DataDisk.DriveLetter + ":"
        $WSUSLocation = "$DriveLetter\WSUS"
        $Setup = 'C:\Program Files\Update Services\Tools\WsusUtil.exe'
        $Argument = "PostInstall SQL_INSTANCE_NAME=$ENV:ComputerName\SQLEXPRESS CONTENT_DIR=$WSUSLocation"
        Start-Process -FilePath $Setup -ArgumentList $Argument -Wait -NoNewWindow
    }
    Default
    {
        Write-Warning "Nothing to do for role $Role"
    }
}
