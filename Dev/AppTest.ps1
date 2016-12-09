[cmdletbinding(SupportsShouldProcess=$true)]
Param
(
    [parameter(position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $SettingsFile = "C:\Setup\FABuilds\FASettings.xml",

    [parameter(Position=1,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx",
    
    [parameter(Position=2,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VMlocation = "D:\VMs",

    [parameter(Position=3,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogPath,

    [parameter(Position=4,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Roles,

    [parameter(Position=5,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Server,

    [parameter(Position=6,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $FinishAction

)

##############

#Init
$Server = "SCOM01"
$Logpath = "C:\Setup\FABuilds\log.txt"

#Set start time
$StartTime = Get-Date

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$ServerName = $Server
$DomainName = "Fabric"
$log = "$env:TEMP\$ServerName" + ".log"

#Read data from XML
Write-Verbose "Reading $SettingsFile"
[xml]$Settings = Get-Content $SettingsFile
$CustomerData = $Settings.FABRIC.Customers.Customer
$CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
$ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
$NetworksData = $Settings.FABRIC.Networks.Network
$DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName
$NIC001 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property id -EQ -Value NIC01
$NIC001RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC001.ConnectedToNetwork

$MountFolder = "C:\MountVHD"
$AdminPassword = $CommonSettingData.LocalPassword
$DomainInstaller = $DomainData.DomainAdmin
$DomainName = $DomainData.DomainAdminDomain
$DNSDomain = $DomainData.DNSDomain
$DomainAdminPassword = $DomainData.DomainAdminPassword
$VMMemory = [int]$ServerData.Memory * 1024 * 1024
$VMSwitchName = $CommonSettingData.VMSwitchName
$localCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)
$VIASetupCompletecmdCommand = "cmd.exe /c PowerShell.exe -Command New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name OSDeployment -Value Done -PropertyType String"
$SetupRoot = "C:\Setup"

#Init End


#Action
$App = "ADK 1607"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
$Source = 'D:\Windows ADK 10 1607\adksetup.exe'
$Configuration = "SCVM"
Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallADK.ps1 -ArgumentList $Source,$Configuration -ErrorAction Stop -Credential $domainCred 

#Action
$App = "SQL 2014 STD SP1"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
$Source = 'D:\SQL 2014 STD SP1\setup.exe'
$SQLINSTANCENAME = "MSSQLSERVER"
$SQLINSTANCEDIR = "E:\SQLDB"
$SQLRole = 'SCVM2016'
Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred

#Restart
Restart-VIAVM -VMname $($ServerData.ComputerName)
Wait-VIAVMIsRunning -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveICLoaded -VMname $($ServerData.ComputerName)
Wait-VIAVMHaveIP -VMname $($ServerData.ComputerName)
Wait-VIAVMHavePSDirect -VMname $($ServerData.ComputerName) -Credentials $domainCred

#Action
$App = "SCVMM 2016"
$Action = "Add Service Account to Local Administrators Group"
Update-VIALog -Data "Action: $Action - $App"
$LocalGroup = "Administrators"
$DomainUser = ($Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCVMM').Name
Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Add-VIADomainuserToLocalgroup.ps1 -ArgumentList $LocalGroup,$DomainUser -ErrorAction Stop  -Credential $domainCred

#Action
$App = "SQL 2014 STD SP1"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
$Source = 'D:\SQL 2014 STD SP1\setup.exe'
$SQLINSTANCENAME = "MSSQLSERVER"
$SQLINSTANCEDIR = "E:\SQLDB"
$SQLRole = 'SCOM2016'
Invoke-Command -VMName $ServerData.ComputerName -FilePath C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSQLServer2014.ps1 -ArgumentList $Source,$SQLRole,$SQLINSTANCENAME,$SQLINSTANCEDIR -ErrorAction Stop  -Credential $domainCred
            


#Action
$App = "SCOM 2016"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
#Install OpsMgr Server
$ServiceAccount = $Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Service Account for SCOM'
$ActionAccount = $Settings.FABRIC.DomainAccounts.DomainAccount | Where-Object AccountDescription -EQ 'Action Account for SCOM'
$Service01 = $Settings.FABRIC.Services.Service | Where-Object Name -EQ SCOM2016
$Source = 'D:\SC 2016 OM\setup.exe'
$SCOMRole = 'OMServer'
Invoke-Command -VMName $($ServerData.ComputerName) -Scriptblock{
    Param(
    $Source,
    $SCOMRole,
    $ManagementGroupName,
    $SqlServerInstance,
    $DWSqlServerInstance,
    $DatareaderUser,
    $DatareaderPassword,
    $ActionAccountUser,
    $ActionAccountPassword
    )
    Write-Host "Using: $Source $SCVMRole $ManagementGroupName $SqlServerInstance $DWSqlServerInstance $DatareaderUser $DatareaderPassword $DataWriterUser $DataWriterPassword $DASAccountUser $DASAccountPassword $ActionAccountUser $ActionAccountPassword"
    C:\Setup\HYDv10\Scripts\Invoke-VIAInstallSCOM2016.ps1 -SCOMSetup $Source -SCOMRole $SCOMRole -ManagementGroupName $ManagementGroupName -SqlServerInstance $SqlServerInstance -DWSqlServerInstance $DWSqlServerInstance -DatareaderUser $DatareaderUser -DatareaderPassword $DatareaderPassword -DataWriterUser $DatareaderUser -DataWriterPassword $DatareaderPassword -DASAccountUser $DatareaderUser -DASAccountPassword $DatareaderPassword -ActionAccountUser $ActionAccountUser -ActionAccountPassword $ActionAccountPassword
} -ArgumentList $Source,$SCOMRole,$($DomainData.DomainNetBios),$($Service01.SQLINSTANCENAME),$($Service01.SQLINSTANCENAME),$($ServiceAccount.Name),$($ServiceAccount.PW),$($ActionAccount.Name),$($ActionAccount.PW) -ErrorAction Stop  -Credential $domainCred





#Action
$App = "SCOM 2016"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
#Install Console
Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
    \\fadepl01\ApplicationRoot\Script\Invoke-FAInstallSCOM.ps1 `
    -SCOMSetup \\fadepl01\ApplicationRoot\Install-SCOM\Source\Setup.exe `
    -SCOMRole OMConsole `
    -Verbose
}

#Action
$App = "SCOM 2016"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
#Install Reporting
Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
    \\fadepl01\ApplicationRoot\Script\Invoke-FAInstallSCOM.ps1 `
    -SCOMSetup \\fadepl01\ApplicationRoot\Install-SCOM\Source\Setup.exe `
    -SCOMRole OMReporting `
    -DataWriterUser $Domain\$DataWriterUser `
    -DataWriterPassword $DataWriterPassword `
    -SRSInstance $SqlServerInstance `
    -Verbose
}

#Action
$App = "SCOM 2016"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
#Install WebConsole
Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
    \\fadepl01\ApplicationRoot\Script\Invoke-FAInstallSCOM.ps1 `
    -SCOMSetup \\fadepl01\ApplicationRoot\Install-SCOM\Source\Setup.exe `
    -SCOMRole OMWebConsole `
    -WebSiteName "Default Web Site" `
    -Verbose
}

#Action
$App = "Set AutoMatic Agent Assigment"
$Action = "Install Application"
Update-VIALog -Data "Action: $Action - $App"
Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
    \\fadepl01\ApplicationRoot\Script\Invoke-FAMomADAdmin.ps1 `
    -ManagementGroupName "$Domain" `
    -MOMAdminSecurityGroup "$Domain\Domain System Center Operations Manager Admins"`
    -RunAsAccount "$Domain\SVC_SCOM_AA"`
    -Domain "$Domain"
}

#Action
$App = "SCOM 2016"
$Action = "Add Product Key and Activate SCOM"
$Settings.Fabric.MachineDefaults.SC2012R2ProductKey
Update-VIALog -Data "Action: $Action - $App"
Invoke-Command -VMName $ServerData.ComputerName -Scriptblock{
    Import-Module 'C:\Program Files\Microsoft System Center 2012 R2\Operations Manager\Powershell\OperationsManager' -Verbose
    Set-SCOMLicense -ProductId $ProductId -Confirm:$false
    Restart-Service "System Center Management Configuration" -Force
    Restart-Service "System Center Data Access Service" -Force
} -ArgumentList

