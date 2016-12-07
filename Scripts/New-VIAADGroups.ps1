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

Param(
    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $BaseOU,

    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $ADGroups
)

# Settinga variables
$CurrentDomain = Get-ADDomain

foreach ($ADGroup in $ADGroups)
{
    Write-Host "Creating: $($ADGroup.Name) in: $($ADGroup.DomainOU) of type: $($ADGroup.GroupScope)"
    $TargetOU = Get-ADOrganizationalUnit -Filter "Name -like '$($ADGroup.DomainOU)'"
    New-ADGroup -Name $($ADGroup.Name) -GroupScope $($ADGroup.GroupScope) -Path $TargetOU.DistinguishedName -Server:$CurrentDomain.PDCEmulator -Verbose
}


