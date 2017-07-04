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
    $CACommonName = 'RootCA',

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=4)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CARootCertLifeTimeYear = '5',

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=5)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CARootCertHashAlgorithmName = '256',

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=6)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CARootCertKeyLengt = '2048'
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
-CAType "EnterpriseRootCA" -HashAlgorithmName $CARootCertHashAlgorithmName -KeyLength $CARootCertKeyLengt -ValidityPeriod Years `
-ValidityPeriodUnits $CARootCertLifeTimeYear -CACommonName "$CACommonName" -OverwriteExistingCAinDS `
-OverwriteExistingKey `
-OverwriteExistingDatabase `
-Force -Verbose -Credential $Credentials
