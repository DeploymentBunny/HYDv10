<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
[Parameter(Mandatory=$true,Position=0)]
  $SQLSetup,

  [Parameter(Mandatory=$false,Position=1)]
  $SQLINSTANCENAME = "SQLExpress",

  [Parameter(Mandatory=$false,Position=2)]
  $SQLINSTANCEDIR = "E:\SQLDB"
)

$unattendFile = New-Item "$env:temp\ConfigutionFile.ini" -type File -Force
set-Content $unattendFile "[OPTIONS]"
add-Content $unattendFile "ACTION=Install"
add-Content $unattendFile "ROLE=""AllFeatures_WithDefaults"""
add-Content $unattendFile "ENU=""True"""
add-Content $unattendFile "QUIET=""True"""
add-Content $unattendFile "QUIETSIMPLE=""False"""
add-Content $unattendFile "UpdateEnabled=""False"""
add-Content $unattendFile "FEATURES=""SQLENGINE,SSMS,SNAC_SDK"""
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
add-Content $unattendFile "ENABLERANU=""True"""
add-Content $unattendFile "SQLCOLLATION=""SQL_Latin1_General_CP1_CI_AS"""
add-Content $unattendFile "SQLSVCACCOUNT=""NT AUTHORITY\NETWORK SERVICE"""
add-Content $unattendFile "SQLSYSADMINACCOUNTS=""BUILTIN\Administrators"""
add-Content $unattendFile "ADDCURRENTUSERASSQLADMIN=""True"""
add-Content $unattendFile "TCPENABLED=""1"""
add-Content $unattendFile "NPENABLED=""1"""
add-Content $unattendFile "BROWSERSVCSTARTUPTYPE=""Automatic"""
add-Content $unattendFile "IACCEPTSQLSERVERLICENSETERMS=""True"""

try
    {
      Write-Host "Install SQL Server, please wait"
      Start-Process -FilePath $SQLSetup -ArgumentList "/ConfigurationFile=$unattendFile"  -Wait -NoNewWindow
    }
Catch
    {
      $ErorMsg = $_.Exception.Message
      Write-Warning "Error during script: $ErrorMsg"
      Break
    }