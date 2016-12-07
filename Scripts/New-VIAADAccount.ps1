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

[cmdletbinding(SupportsShouldProcess=$True)]

Param
(
    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $BaseOU,

    [parameter(mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    $Accounts
)

$CurrentDomain = Get-ADDomain
foreach ($Account in $Accounts){
    switch ($($Account.AccountType)){
        'AdminAccount' {
            $TargetOU = (Get-ADOrganizationalUnit -Filter "Name -like '$($Account.OUName)'").DistinguishedName
            $SecurePassword = ConvertTo-SecureString -String $Account.PW -AsPlainText -Force
            New-ADUser `
            -Description $($Account.AccountDescription) `
            -DisplayName $($Account.Name) `
            -GivenName $($Account.Name) `
            -Name $($Account.Name) `
            -Path $TargetOU `
            -SamAccountName $($Account.Name) `
            -CannotChangePassword $false `
            -PasswordNeverExpires $true `
            -ChangePasswordAtLogon $False
            $NewAccount = Get-ADUser $($Account.Name)
            Set-ADAccountPassword $NewAccount -NewPassword $SecurePassword
            #Set-ADAccountControl $NewAccount -CannotChangePassword $false -PasswordNeverExpires $true
            #Set-ADUser $NewAccount -ChangePasswordAtLogon $False 
            Enable-ADAccount $NewAccount
        }
        'ServiceAccount' {
            $TargetOU = (Get-ADOrganizationalUnit -Filter "Name -like '$($Account.OUName)'").DistinguishedName
            $SecurePassword = ConvertTo-SecureString -String $Account.PW -AsPlainText -Force
            New-ADUser `
            -Description $($Account.AccountDescription) `
            -DisplayName $($Account.Name) `
            -GivenName $($Account.Name) `
            -Name $($Account.Name) `
            -Path $TargetOU `
            -SamAccountName $($Account.Name) `
            -CannotChangePassword $true `
            -PasswordNeverExpires $true `
            -ChangePasswordAtLogon $false
            $NewAccount = Get-ADUser $($Account.Name)
            Set-ADAccountPassword $NewAccount -NewPassword $SecurePassword 
            #Set-ADAccountControl $NewAccount -CannotChangePassword $false -PasswordNeverExpires $true
            #Set-ADUser $NewAccount -ChangePasswordAtLogon $False 
            Enable-ADAccount $NewAccount
        }
        'UserAccount' {
            $TargetOU = (Get-ADOrganizationalUnit -Filter "Name -like '$($Account.OUName)'").DistinguishedName
            $SecurePassword = ConvertTo-SecureString -String $Account.PW -AsPlainText -Force
            New-ADUser `
            -Description $($Account.AccountDescription) `
            -DisplayName $($Account.Name) `
            -GivenName $($Account.Name) `
            -Name $($Account.Name) `
            -Path $TargetOU `
            -SamAccountName $($Account.Name) `
            -CannotChangePassword $false `
            -PasswordNeverExpires $true `
            -ChangePasswordAtLogon $False 
            $NewAccount = Get-ADUser $($Account.Name)
            Set-ADAccountPassword $NewAccount -NewPassword $SecurePassword
            #Set-ADAccountControl $NewAccount -CannotChangePassword $false -PasswordNeverExpires $true
            #Set-ADUser $NewAccount -ChangePasswordAtLogon $False 
            Enable-ADAccount $NewAccount
        }
        Default {}
    }
}

