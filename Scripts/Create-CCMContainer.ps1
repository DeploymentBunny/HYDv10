<#
        .SYNOPSIS
        Creates the System Management Container in Active Directory for ConfigMgr installation

        .DESCRIPTION
        Script will create the AD Container System Management and assign permissions for the 
        SCCM Server

        .PARAMETER ConfigMgrSrv
        Allows the user to specify the ConfigMgr server account name
        defaults to hostname of the server where the script is being run

        .INPUTS
        None

        .OUTPUTS
        <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

        .NOTES
        Version:        1.0p
        Author:         Daniele Catanesi
        Creation Date:  09.07.2015
        WebSite:        http://blog.helocheck.com
        Contact:        helocheck@helocheck.com
        Purpose/Change: Initial script development
                        and release to public
  
        .EXAMPLE
        To specify the ConfigMgr server name use
        Create-CCMContainer.ps1 -ConfigMgrSrv SRV-CCM01

        To use default value of $env:COMPUTERNAME use
        Create-CCMContainer.ps1
#>

# Declare and set default value for ConfigMgrSrv parameter
Param(
    $ConfigMgrSrv = $env:COMPUTERNAME
)

#Import AD module if not already loaded
Import-Module -Name ActiveDirectory

# Derive domain name
$namingContext = (Get-ADRootDSE).defaultNamingContext

# Define path for System Management Container
$sccmContainer = "CN=System Management,CN=System,$namingContext"

# Check if the Container exists
if ([adsi]::Exists("LDAP://$sccmContainer") -eq $false)  
{
    # Write informative message and create container
    Write-Host -Object 'System Management Container does not exist and will be created!' -ForegroundColor Green
    # Create System Management Container
    New-ADObject -Type Container -Name 'System Management' -Path "CN=System, $namingContext" -Passthru
}

Else

{
    # If container already exists write a message and exit
    Write-Host -Object 'System Management Container already exists! Script will terminate now!' -ForegroundColor Red
    # Set exit code to 5
    Exit 5
}


# Get SID of SCCM Server
$configMgrSid = [System.Security.Principal.IdentityReference] (Get-ADComputer $ConfigMgrSrv).SID

# Get current ACL set for System Management Container
$cnACL = Get-Acl -Path "ad:$sccmContainer"

# Sepcify Permission to Full Control
$adPermissions = [System.DirectoryServices.ActiveDirectoryRights] 'GenericAll'

# Specify Permission type to allow access
$permissionType = [System.Security.AccessControl.AccessControlType] 'Allow'

# Set Inheritance for the Container to "This object and all child objects"
$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] 'All'

# Set System Management container Access Control Entry
$cnACE = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList $configMgrSid, $adPermissions, $permissionType , $inheritanceType

# Add Access Control Entry to existing ACL
$cnACL.AddAccessRule($cnACE) 

# Finally Set ACL on System Management Container
Set-Acl -AclObject $cnACL -Path "AD:$sccmContainer"

# Write Success message
Write-Host -Object 'System Management Container has been successfully created!' -ForegroundColor Green