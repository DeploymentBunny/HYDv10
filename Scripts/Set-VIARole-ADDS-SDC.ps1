<#
Created:	 2016-12-06
Version:	 2.0
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
    $Password,
    
    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $FQDN,
    
    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $NetBiosDomainName,

    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $DomainForestLevel,

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    $DatabaseRoot = "C:\Windows",

    [parameter(mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    $SiteName
)


#Windows Server 2012 R2 = ws2012r2
#Windows Server 2016 = WinThreshold


switch ($DomainForestLevel)
{
    'ws2012r2' {$Mode = 'ws2012r2'}
    'ws2016' {$Mode = 'WinThreshold'}
    Default {Break}
}

Write-Host $Password
Write-Host $FQDN
Write-Host $NetBiosDomainName
Write-Host $DomainForestLevel
Write-Host $DatabaseRoot

# Setting variables
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

# Configure Active Directory and DNS
Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-CriticalReplicationOnly:$false `
-DatabasePath "$DatabaseRoot\NTDS" `
-DomainName $FQDN `
-InstallDns:$true `
-SafeModeAdministratorPassword $SecurePassword `
-LogPath "$DatabaseRoot\NTDS" `
-NoRebootOnCompletion:$True `
-SiteName $SiteName `
-SysvolPath "$DatabaseRoot\SYSVOL" `
-Force:$true

Start-Sleep -Seconds 15