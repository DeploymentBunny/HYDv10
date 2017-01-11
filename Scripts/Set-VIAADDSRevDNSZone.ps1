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
[CmdletBinding(DefaultParameterSetName='Param Set 1', 
                SupportsShouldProcess=$true, 
                PositionalBinding=$true)]
Param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    $RevDNSZones
)

#Create RevZone
foreach($RevDNSZone in $RevDNSZones){
    Write-Verbose "Adding $RevDNSZone"
    Get-DnsServerZone
    Add-DnsServerPrimaryZone -Name $RevDNSZone -ReplicationScope Forest
    Get-DnsServerZone
}
