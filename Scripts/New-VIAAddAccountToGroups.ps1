<#
Created:	 2013-12-16
Version:	 1.0
Author       Mikael Nystrom and Johan Arwidmark       
Homepage:    http://www.deploymentfundamentals.com

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the authors or DeploymentArtist.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com
#>

[cmdletbinding(SupportsShouldProcess=$true)]

Param
(
    [parameter(Position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    $BaseOU,

    [parameter(Position=1,mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $Accounts
)

$CurrentDomain = Get-ADDomain

foreach ($Account in $Accounts){
    foreach ($Group in $($Account.MemberOf)){
        $TargetGroup = Get-AdGroup -Filter "Name -like '$Group'"
        $TargetAccount = Get-AdUser -Filter "Name -like '$($Account.Name)'"
        Write-Verbose "Adding $TargetAccount to $TargetGroup"
        Add-ADGroupMember -Identity $TargetGroup -Members $TargetAccount -Server $($CurrentDomain.PDCEmulator)
    }
}
