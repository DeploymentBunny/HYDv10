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
)

#Action
$Action = "Authorize the DHCP Server"
Write-Verbose "Action: $Action"
Add-DhcpServerInDC
Start-Sleep 2

#Action
$Action = "Add Security Groups"
Write-Verbose "Action: $Action"
Add-DhcpServerSecurityGroup
Start-Sleep 2

#Action
$Action = "Making the ServerManager happy (Flag DHCP as configured)"
Write-Verbose "Action: $Action"
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2 -Force
Start-Sleep 2

#Action
$Action = "Restart Service"
Write-Verbose "Action: $Action"
Restart-Service "DHCP Server" -Force
Start-Sleep 2
