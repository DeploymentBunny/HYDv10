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
    [CmdletBinding(DefaultParameterSetName='Param Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$true)]
Param
(
    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccount,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccountPassword,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CACommonName = 'NA'
)

#Set CA name if not set
if($CACommonName = 'NA'){$CACommonName = 'Fabric-root-CA'}

#Action Create Credentials
$SecurePassword = $RunAsAccountPassword | ConvertTo-SecureString -AsPlainText -Force
$AdministratorName = $RunAsAccount
$LogonDomain = $env:USERDOMAIN
$UserName = "$LogonDomain\$AdministratorName"
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName,$SecurePassword

#Install CA
Install-AdcsCertificationAuthority `
-CAType "EnterpriseRootCA" -HashAlgorithmName SHA256 -KeyLength 2048 -ValidityPeriod Years `
-ValidityPeriodUnits 5 -CACommonName "$CACommonName" -OverwriteExistingCAinDS `
-OverwriteExistingKey `
-OverwriteExistingDatabase `
-Force -Verbose -Credential $Credentials
