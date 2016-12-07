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

[CmdletBinding()]

Param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    $SiteName,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
    $ADSubnets
)

foreach ($ADSubnet in $ADSubnets)
{
    # Create AD Subnet 
    Write-Verbose "Adding $ADSubnet to $SiteName"
    New-ADReplicationSubnet -Name $ADSubnet -Site $SiteName
}
