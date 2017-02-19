<#
.Synopsis
    Script for Deployment Fundamentals Vol 7
.DESCRIPTION
    Script for Deployment Fundamentals Vol 7
.EXAMPLE
    C:\Setup\Scripts\Set-VIASQLMemoryConfiguration.ps1 -SQLInstance SQLEXPRESS
.NOTES
    Created:	 July 15, 2016
    Version:	 1.0

    Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

    Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

    Disclaimer:
    This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the authors or Deployment Artist.
.LINK
    http://www.deploymentfundamentals.com
#>

[cmdletbinding(SupportsShouldProcess=$True)]
Param (
    [Parameter(Mandatory=$False,Position=0)]
    $SQLInstance = "Default"
)

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Throw
}

$CurrentAmountOfMemory = Get-WMIObject -class WIN32_PhysicalMemory
$FreeMemoryGB = ([Math]::round($CurrentAmountOfMemory.Capacity[0] / 1024 / 1024))
Write-Output "Current amount of memory $FreeMemoryGB"
    
if($FreeMemoryGB -ge 15900)
{
    $SQLMaximumMemory = ([Math]::Round(0.7 * $FreeMemoryGB))
}
else
{
    $SQLMaximumMemory = ([Math]::Round(0.5 * $FreeMemoryGB))
}
    
Write-Output "Setting $SQLMaximumMemory as SQL Max Mem"

$SQLConfigurationFile = New-Item "$env:temp\SetMaximumMemory.sql" -type File -Force
set-Content $SQLConfigurationFile "EXEC sp_configure 'show advanced options', '1'"
add-Content $SQLConfigurationFile "RECONFIGURE WITH OVERRIDE"
add-Content $SQLConfigurationFile "EXEC sp_configure 'max server memory', '$SQLMaximumMemory'"
add-Content $SQLConfigurationFile "RECONFIGURE WITH OVERRIDE" 
add-Content $SQLConfigurationFile "EXEC sp_configure 'show advanced options', '0'"
add-Content $SQLConfigurationFile "RECONFIGURE WITH OVERRIDE" 

Get-Content $SQLConfigurationFile

$Setup = "C:\Program Files\Microsoft SQL Server\120\Tools\Binn\osql.exe"

if($SQLInstance -ne "Default")
{
    Write-Verbose "SQLInstance is $SQLInstance"
    $Arguments = "-S $env:COMPUTERNAME\$SQLInstance -E -i $SQLConfigurationFile -o $env:temp\Configure-SQLServerMemory_osql_output.log"
    Write-Verbose $Arguments
}
else
{
    Write-Verbose "SQLInstance is not specified, trying Default"
    $Arguments = "-S $env:COMPUTERNAME -E -i $SQLConfigurationFile -o $env:temp\Configure-SQLServerMemory_osql_output.log"
    Write-Verbose $Arguments
}

try
    {
      Write-Output "Executing.."
      $Process = Start-Process -FilePath $Setup -ArgumentList $Arguments -NoNewWindow -PassThru -Wait
      Write-Output "Process finished with return code: " $Process.ExitCode
      Get-Content "$env:temp\Configure-SQLServerMemory_osql_output.log"
    }
Catch
    {
      $ErorMsg = $_.Exception.Message
      Write-Warning "Error during script: $ErrorMsg"
      Break
    }
