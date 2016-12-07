Param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    $SiteName
)
# Change name of Default Site
Write-Verbose "Change site name to $SiteName"
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Where-Object -Property Name -like "Default-First-Site-Name" | Rename-ADObject -NewName "$SiteName"
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'"