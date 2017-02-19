<#
.Synopsis
    Script for Deployment Fundamentals Vol 7
.DESCRIPTION
    Script for Deployment Fundamentals Vol 7
.EXAMPLE
    C:\Setup\Scripts\Set-VIASQLFirewall.ps1
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
param()

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Throw
}

# Configuration of firewall for MDT (SQL Browser Service)
New-NetFirewallRule -DisplayName "SQL Server Browser Service" -Direction Inbound –Protocol UDP –LocalPort 1434 -Action allow