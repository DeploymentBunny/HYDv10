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
    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccount,

    [parameter(mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=3)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RunAsAccountPassword
)

#Action Create Credentials
$SecurePassword = $RunAsAccountPassword | ConvertTo-SecureString -AsPlainText -Force
$AdministratorName = $RunAsAccount
$LogonDomain = $env:USERDOMAIN
$UserName = "$LogonDomain\$AdministratorName"
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName,$SecurePassword


Install-AdcsCertificationAuthority `
-CAType "EnterpriseRootCA" -HashAlgorithmName SHA256 -KeyLength 2048 -ValidityPeriod Years `
-ValidityPeriodUnits 5 -CACommonName "Fabric-root-CA" -OverwriteExistingCAinDS `
-OverwriteExistingKey `
-OverwriteExistingDatabase `
-Force -Verbose -Credential $Credentials
