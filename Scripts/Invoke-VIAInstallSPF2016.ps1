<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $SPFSetup,

    [Parameter(Mandatory=$false,Position=1)]
    $SPFDomain,

    [Parameter(Mandatory=$false,Position=1)]
    $SPFServiceAccount,

    [Parameter(Mandatory=$false,Position=1)]
    $SPFServiceAccountPW,

    [Parameter(Mandatory=$false,Position=2)]
    $DatabaseServer,

    [Parameter(Mandatory=$false,Position=3)]
    $VmmSecurityGroupUsers,

    [Parameter(Mandatory=$false,Position=4)]
    $AdminSecurityGroupUsers,

    [Parameter(Mandatory=$false,Position=5)]
    $ProviderSecurityGroupUsers,

    [Parameter(Mandatory=$false,Position=6)]
    $usageSecurityGroupUsers
)

$unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
Set-Content $unattendFile "-SendCEIPReports false"
Add-Content $unattendFile "-UseMicrosoftUpdate false"
Add-Content $unattendFile "-SpecifyCertificate false"
Add-Content $unattendFile "-DatabaseServer $DatabaseServer"
Add-Content $unattendFile "-VmmSecurityGroupUsers $VmmSecurityGroupUsers"
Add-Content $unattendFile "-AdminSecurityGroupUsers $AdminSecurityGroupUsers"
Add-Content $unattendFile "-ProviderSecurityGroupUsers $ProviderSecurityGroupUsers"
Add-Content $unattendFile "-usageSecurityGroupUsers $usageSecurityGroupUsers"
Add-Content $unattendFile "-ScvmmNetworkServiceSelected false"
Add-Content $unattendFile "-ScadminNetworkServiceSelected false"
Add-Content $unattendFile "-ScproviderNetworkServiceSelected false"
Add-Content $unattendFile "-ScusageNetworkServiceSelected false"
Add-Content $unattendFile "-ScvmmDomain $SPFDomain"
Add-Content $unattendFile "-ScadminDomain $SPFDomain"
Add-Content $unattendFile "-ScproviderDomain $SPFDomain"
Add-Content $unattendFile "-ScusageDomain $SPFDomain"
Add-Content $unattendFile "-ScvmmPassword $SPFServiceAccountPW"
Add-Content $unattendFile "-ScadminPassword $SPFServiceAccountPW"
Add-Content $unattendFile "-ScproviderPassword $SPFServiceAccountPW"
Add-Content $unattendFile "-ScusagePassword $SPFServiceAccountPW"
Add-Content $unattendFile "-ScvmmUserName $SPFServiceAccount"
Add-Content $unattendFile "-ScadminUserName $SPFServiceAccount"
Add-Content $unattendFile "-ScproviderUserName $SPFServiceAccount"
Add-Content $unattendFile "-ScusageUserName $SPFServiceAccount"


$Setup = $SPFSetup
$sArgument = " -Silent $unattendFile"
$Process = Start-Process $Setup -ArgumentList $sArgument -NoNewWindow -PassThru -Wait
$ExeExitCode = $Process.ExitCode
Write-Verbose "Process finished with return code: $ExeExitCode" 


