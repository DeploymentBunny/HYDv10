<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

[cmdletbinding(SupportsShouldProcess=$True)]

Param
(
    [parameter(mandatory=$True,ValueFromPipelineByPropertyName=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    $LocalGroup,

    [parameter(mandatory=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    $DomainUser
)

#Add Domain USer to LocalGroup
Write-Output "Adding $env:USERDOMAIN\$DomainUser to $LocalGroup on $env:COMPUTERNAME"
$LG = [ADSI]"WinNT://$env:COMPUTERNAME/$LocalGroup,group" 
$LG.psbase.Invoke("Add",([ADSI]"WinNT://$env:USERDOMAIN/$DomainUser").path)
