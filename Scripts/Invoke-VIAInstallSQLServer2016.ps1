<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $SQLSetup,

    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("Default","SCOR","SCVM","SCVMM2016")]
    $SQLRole = "Default",

    [Parameter(Mandatory=$true,Position=2)]
    $SQLINSTANCENAME,

    [Parameter(Mandatory=$true,Position=3)]
    $SQLINSTANCEDIR
)

switch ($SQLRole)
{
    SCOR
    {
        $unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
        set-Content $unattendFile "[OPTIONS]"
        add-Content $unattendFile "ACTION=Install"
        add-Content $unattendFile "ENU=""True"""
        add-Content $unattendFile "QUIET=""True"""
        add-Content $unattendFile "QUIETSIMPLE=""False"""
        add-Content $unattendFile "UpdateEnabled=""False"""
        add-Content $unattendFile "FEATURES=SQLENGINE,TOOLS,ADV_SSMS"
        add-Content $unattendFile "UpdateSource=""MU"""
        add-Content $unattendFile "HELP=""False"""
        add-Content $unattendFile "INDICATEPROGRESS=""False"""
        add-Content $unattendFile "X86=""False"""
        add-Content $unattendFile "INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server"""
        add-Content $unattendFile "INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server"""
        add-Content $unattendFile "INSTANCENAME=""$SQLINSTANCENAME"""
        add-Content $unattendFile "INSTANCEID=""$SQLINSTANCENAME"""
        add-Content $unattendFile "SQMREPORTING=""False"""
        add-Content $unattendFile "ERRORREPORTING=""False"""
        add-Content $unattendFile "INSTANCEDIR=""$SQLINSTANCEDIR"""
        add-Content $unattendFile "AGTSVCACCOUNT=""NT AUTHORITY\SYSTEM"""
        add-Content $unattendFile "AGTSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "COMMFABRICPORT=""0"""
        add-Content $unattendFile "COMMFABRICNETWORKLEVEL=""0"""
        add-Content $unattendFile "COMMFABRICENCRYPTION=""0"""
        add-Content $unattendFile "MATRIXCMBRICKCOMMPORT=""0"""
        add-Content $unattendFile "SQLSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "FILESTREAMLEVEL=""0"""
        add-Content $unattendFile "SQLCOLLATION=""SQL_Latin1_General_CP1_CI_AS"""
        add-Content $unattendFile "SQLSVCACCOUNT=""NT AUTHORITY\NETWORK SERVICE"""
        add-Content $unattendFile "SQLSYSADMINACCOUNTS=""BUILTIN\Administrators"""
        add-Content $unattendFile "TCPENABLED=""1"""
        add-Content $unattendFile "NPENABLED=""1"""
        add-Content $unattendFile "BROWSERSVCSTARTUPTYPE=""Disabled"""
        add-Content $unattendFile "IACCEPTSQLSERVERLICENSETERMS=""True"""
    }
    SCVM
    {
        $unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
        set-Content $unattendFile "[OPTIONS]"
        add-Content $unattendFile "ACTION=Install"
        add-Content $unattendFile "ENU=""True"""
        add-Content $unattendFile "QUIET=""True"""
        add-Content $unattendFile "QUIETSIMPLE=""False"""
        add-Content $unattendFile "UpdateEnabled=""False"""
        add-Content $unattendFile "FEATURES=SQLENGINE,TOOLS,ADV_SSMS"
        add-Content $unattendFile "UpdateSource=""MU"""
        add-Content $unattendFile "HELP=""False"""
        add-Content $unattendFile "INDICATEPROGRESS=""False"""
        add-Content $unattendFile "X86=""False"""
        add-Content $unattendFile "INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server"""
        add-Content $unattendFile "INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server"""
        add-Content $unattendFile "INSTANCENAME=""$SQLINSTANCENAME"""
        add-Content $unattendFile "INSTANCEID=""$SQLINSTANCENAME"""
        add-Content $unattendFile "SQMREPORTING=""False"""
        add-Content $unattendFile "ERRORREPORTING=""False"""
        add-Content $unattendFile "INSTANCEDIR=""$SQLINSTANCEDIR"""
        add-Content $unattendFile "AGTSVCACCOUNT=""NT AUTHORITY\SYSTEM"""
        add-Content $unattendFile "AGTSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "COMMFABRICPORT=""0"""
        add-Content $unattendFile "COMMFABRICNETWORKLEVEL=""0"""
        add-Content $unattendFile "COMMFABRICENCRYPTION=""0"""
        add-Content $unattendFile "MATRIXCMBRICKCOMMPORT=""0"""
        add-Content $unattendFile "SQLSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "FILESTREAMLEVEL=""0"""
        add-Content $unattendFile "SQLCOLLATION=""SQL_Latin1_General_CP1_CI_AS"""
        add-Content $unattendFile "SQLSVCACCOUNT=""NT AUTHORITY\NETWORK SERVICE"""
        add-Content $unattendFile "SQLSYSADMINACCOUNTS=""BUILTIN\Administrators"""
        add-Content $unattendFile "TCPENABLED=""1"""
        add-Content $unattendFile "NPENABLED=""1"""
        add-Content $unattendFile "BROWSERSVCSTARTUPTYPE=""Disabled"""
        add-Content $unattendFile "IACCEPTSQLSERVERLICENSETERMS=""True"""
    }
    SCVMM2016
    {
        $unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
        set-Content $unattendFile "[OPTIONS]"
        add-Content $unattendFile "ACTION=Install"
        add-Content $unattendFile "ENU=""True"""
        add-Content $unattendFile "QUIET=""True"""
        add-Content $unattendFile "QUIETSIMPLE=""False"""
        add-Content $unattendFile "UpdateEnabled=""False"""
        add-Content $unattendFile "FEATURES=SQLENGINE,TOOLS,ADV_SSMS"
        add-Content $unattendFile "UpdateSource=""MU"""
        add-Content $unattendFile "HELP=""False"""
        add-Content $unattendFile "INDICATEPROGRESS=""False"""
        add-Content $unattendFile "X86=""False"""
        add-Content $unattendFile "INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server"""
        add-Content $unattendFile "INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server"""
        add-Content $unattendFile "INSTANCENAME=""$SQLINSTANCENAME"""
        add-Content $unattendFile "INSTANCEID=""$SQLINSTANCENAME"""
        add-Content $unattendFile "SQMREPORTING=""False"""
        add-Content $unattendFile "ERRORREPORTING=""False"""
        add-Content $unattendFile "INSTANCEDIR=""$SQLINSTANCEDIR"""
        add-Content $unattendFile "AGTSVCACCOUNT=""NT AUTHORITY\SYSTEM"""
        add-Content $unattendFile "AGTSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "COMMFABRICPORT=""0"""
        add-Content $unattendFile "COMMFABRICNETWORKLEVEL=""0"""
        add-Content $unattendFile "COMMFABRICENCRYPTION=""0"""
        add-Content $unattendFile "MATRIXCMBRICKCOMMPORT=""0"""
        add-Content $unattendFile "SQLSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "FILESTREAMLEVEL=""0"""
        add-Content $unattendFile "SQLCOLLATION=""SQL_Latin1_General_CP1_CI_AS"""
        add-Content $unattendFile "SQLSVCACCOUNT=""NT AUTHORITY\NETWORK SERVICE"""
        add-Content $unattendFile "SQLSYSADMINACCOUNTS=""BUILTIN\Administrators"""
        add-Content $unattendFile "TCPENABLED=""1"""
        add-Content $unattendFile "NPENABLED=""1"""
        add-Content $unattendFile "BROWSERSVCSTARTUPTYPE=""Disabled"""
        add-Content $unattendFile "IACCEPTSQLSERVERLICENSETERMS=""True"""
    }
    Default
    {
        $unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
        set-Content $unattendFile "[OPTIONS]"
        add-Content $unattendFile "ACTION=Install"
        add-Content $unattendFile "ROLE=""AllFeatures_WithDefaults"""
        add-Content $unattendFile "ENU=""True"""
        add-Content $unattendFile "QUIET=""True"""
        add-Content $unattendFile "QUIETSIMPLE=""False"""
        add-Content $unattendFile "UpdateEnabled=""False"""
        add-Content $unattendFile "FEATURES=SQLENGINE,SSMS,SNAC_SDK"
        add-Content $unattendFile "UpdateSource=""MU"""
        add-Content $unattendFile "HELP=""False"""
        add-Content $unattendFile "INDICATEPROGRESS=""False"""
        add-Content $unattendFile "X86=""False"""
        add-Content $unattendFile "INSTALLSHAREDDIR=""C:\Program Files\Microsoft SQL Server"""
        add-Content $unattendFile "INSTALLSHAREDWOWDIR=""C:\Program Files (x86)\Microsoft SQL Server"""
        add-Content $unattendFile "INSTANCENAME=""$SQLINSTANCENAME"""
        add-Content $unattendFile "INSTANCEID=""$SQLINSTANCENAME"""
        add-Content $unattendFile "SQMREPORTING=""False"""
        add-Content $unattendFile "ERRORREPORTING=""False"""
        add-Content $unattendFile "INSTANCEDIR=""$SQLINSTANCEDIR"""
        add-Content $unattendFile "AGTSVCACCOUNT=""NT AUTHORITY\NETWORK SERVICE"""
        add-Content $unattendFile "AGTSVCSTARTUPTYPE=""Disabled"""
        add-Content $unattendFile "COMMFABRICPORT=""0"""
        add-Content $unattendFile "COMMFABRICNETWORKLEVEL=""0"""
        add-Content $unattendFile "COMMFABRICENCRYPTION=""0"""
        add-Content $unattendFile "MATRIXCMBRICKCOMMPORT=""0"""
        add-Content $unattendFile "SQLSVCSTARTUPTYPE=""Automatic"""
        add-Content $unattendFile "FILESTREAMLEVEL=""0"""
        add-Content $unattendFile "SQLCOLLATION=""SQL_Latin1_General_CP1_CI_AS"""
        add-Content $unattendFile "SQLSVCACCOUNT=""NT AUTHORITY\NETWORK SERVICE"""
        add-Content $unattendFile "SQLSYSADMINACCOUNTS=""BUILTIN\Administrators"""
        add-Content $unattendFile "TCPENABLED=""1"""
        add-Content $unattendFile "NPENABLED=""1"""
        add-Content $unattendFile "BROWSERSVCSTARTUPTYPE=""Disabled"""
        add-Content $unattendFile "IACCEPTSQLSERVERLICENSETERMS=""True"""
    }
}


if((Test-Path -Path $SQLSetup) -eq $false){Write-Warning "Could not find $SQLSetup";Break}
if((Test-Path -Path ($SQLINSTANCEDIR | Split-Path -Parent)) -eq $false){Write-Warning "Could not find $($SQLINSTANCEDIR | Split-Path -Parent)";Break}

try
{
    Write-Output "Executing.."
    $Process = Start-Process -FilePath $SQLSetup -ArgumentList "/ConfigurationFile=$unattendFile" -NoNewWindow -PassThru -Wait
    Write-Output "Process finished with return code: " $Process.ExitCode
}
Catch
{
    $ErorMsg = $_.Exception.Message
    Write-Warning "Error during script: $ErrorMsg"
    Break
}
