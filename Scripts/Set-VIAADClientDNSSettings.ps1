<#
Created:	 2015-02-06
Version:	 1.0
Author       Mikael Nystrom

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com
#>

[CmdletBinding(SupportsShouldProcess=$true)]
Param(
    $ClientDNSServerAddr
)

Write-Host $ClientDNSServerAddr
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -ServerAddresses $ClientDNSServerAddr
