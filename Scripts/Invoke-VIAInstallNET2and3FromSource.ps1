<#
 # Will add .NET 2/3 from source folder
#>

Param(
    $SourceFolder
)
Add-WindowsFeature -Name Net-Framework-Core -IncludeAllSubFeature -IncludeManagementTools -Source $SourceFolder