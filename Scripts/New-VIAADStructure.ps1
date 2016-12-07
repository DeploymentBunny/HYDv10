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
    $OUs

)
# Settinga variables
$CurrentDomain = Get-ADDomain

foreach ($OU in $OUs)
{
    $($OU.Name)
    $($OU.Path)

    If($($OU.Path) -eq "Root")
    {
        New-ADOrganizationalUnit -Name:"$($OU.Name)" -Path:"OU=$BaseOU,$CurrentDomain" -ProtectedFromAccidentalDeletion:$True -Server:$CurrentDomain.PDCEmulator
    }
    else
    {
        New-ADOrganizationalUnit -Name:"$($OU.Name)" -Path:"$($OU.Path),OU=$BaseOU,$CurrentDomain" -ProtectedFromAccidentalDeletion:$True -Server:$CurrentDomain.PDCEmulator
    }
}

