<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $Setup
)
Write-Output "Install AspNetMVC4Setup"
$sArgument = " /q"
$Process = Start-Process $Setup -ArgumentList $sArgument -NoNewWindow -PassThru -Wait
$ExeExitCode = $Process.ExitCode
Write-Verbose "Process finished with return code: $ExeExitCode" 
#Test-Path -Path 'HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall\{e9e06304-a604-434b-b35f-d9beb94dc06d}'
