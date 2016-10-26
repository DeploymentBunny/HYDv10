<#
.Synopsis
    Script for Deployment Fundamentals Vol 6
.DESCRIPTION
    Script for Deployment Fundamentals Vol 6
.EXAMPLE
    C:\Setup\Scripts\Install-VIARoles.ps1 -Role DEPL
.NOTES
    Created:	 2015-12-15
    Version:	 1.0

    Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

    Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com

    Disclaimer:
    This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the authors or Deployment Artist.
.LINK
    http://www.deploymentfundamentals.com
#>

[cmdletbinding(SupportsShouldProcess=$True)]
Param
(
    [parameter(mandatory=$True,ValueFromPipelineByPropertyName=$true,Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("FILE","RDGW","ADDS","DHCP","RRAS","RDGW","MGMT","DEPL","ADCA","WSUS","SCVM","SCVMM2016","SCOR","BitLockerAdmin","WEB","Storage","Compute","S2D")]
    $Role
)

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Oupps, you need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Throw
}

switch ($Role)
{
    S2D
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "FS-FileServer",
        "Data-Center-Bridging",
        "Failover-Clustering"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    Storage
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "FS-FileServer",
        "FS-Data-Deduplication",
        "FS-VSS-Agent",
        "Storage-Services",
        "Data-Center-Bridging",
        "Failover-Clustering",
        "Multipath-IO"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    Compute
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "Hyper-V"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    FILE
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "FS-FileServer",
        "FS-Data-Deduplication"
        "FS-DFS-Namespace",
        "FS-DFS-Replication"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    RDGW
    {
        Write-Output "Adding Windows Features for $Role"
        Install-WindowsFeature -Name "RDS-GateWay" -IncludeManagementTools -IncludeAllSubFeature -ErrorAction Stop
    }
    ADDS
    {
        Write-Output "Adding Windows Features for $Role"
        Add-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
    }
    DHCP
    {
        Write-Output "Adding Windows Features for $Role"
        Add-WindowsFeature -Name DHCP -IncludeManagementTools
        Start-Sleep 2

    }
    RRAS
    {
        Write-Output "Adding Windows Features for $Role"
        Install-WindowsFeature Routing -IncludeManagementTools
        Install-RemoteAccess -VpnType Vpn
    }
    RDGW
    {
        Write-Output "Adding Windows Features for $Role"
        Install-WindowsFeature -Name RDS-GateWay -IncludeManagementTools -IncludeAllSubFeature
    }
    MGMT
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "RDS-RD-Server",
        "Web-Metabase",
        "Web-Lgcy-Mgmt-Console",
        "NET-WCF-TCP-PortSharing45",
        "GPMC",
        "CMAK",
        "RSAT-SMTP",
        "RSAT-Feature-Tools-BitLocker",
        "RSAT-Bits-Server",
        "RSAT-Clustering-Mgmt",
        "RSAT-Clustering-PowerShell",
        "RSAT-NLB",
        "RSAT-SNMP",
        "RSAT-AD-PowerShell",
        "RSAT-AD-AdminCenter",
        "RSAT-ADDS-Tools",
        "Hyper-V-Tools",
        "Hyper-V-PowerShell",
        "RSAT-RDS-Licensing-Diagnosis-UI",
        "UpdateServices-API",
        "UpdateServices-UI",
        "RSAT-ADCS-Mgmt",
        "RSAT-Online-Responder",
        "RSAT-DHCP",
        "RSAT-DNS-Server",
        "RSAT-DFS-Mgmt-Con",
        "RSAT-FSRM-Mgmt",
        "RSAT-NFS-Admin",
        "RSAT-RemoteAccess-Mgmt",
        "RSAT-RemoteAccess-PowerShell",
        "RSAT-VA-Tools",
        "WDS-AdminPack",
        "Telnet-Client",
        "XPS-Viewer",
        "VolumeActivation"
        )
        Install-WindowsFeature -Name $ServicesToInstall
    }
    DEPL
    {
        Write-Output "Adding Windows Features for $Role"
        Add-WindowsFeature -Name WDS -IncludeAllSubFeature -IncludeManagementTools
        Add-WindowsFeature -Name FS-FileServer,FS-Data-Deduplication
    }
    ADCA
    {
        Write-Output "Adding Windows Features for $Role"
        Add-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools
    }
    WSUS
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "UpdateServices-Services",
        "UpdateServices-DB"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    SCVM
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "Hyper-V-Tools",
        "Hyper-V-PowerShell",
        "UpdateServices-API",
        "UpdateServices-UI"
        "UpdateServices-RSAT",
        "RSAT-Clustering",
        "RSAT-AD-Tools",
        "RSAT-DHCP",
        "RSAT-DNS-Server",
        "WDS-AdminPack"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    SCVMM2016
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "Hyper-V-Tools",
        "Hyper-V-PowerShell",
        "UpdateServices-API",
        "UpdateServices-UI"
        "UpdateServices-RSAT",
        "RSAT-Clustering",
        "RSAT-AD-Tools",
        "RSAT-DHCP",
        "RSAT-DNS-Server",
        "WDS-AdminPack"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    SCOR
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "Web-Common-Http",
        "Web-Static-Content",
        "Web-Default-Doc",
        "Web-Dir-Browsing",
        "Web-Http-Errors",
        "Web-Http-Logging",
        "Web-Request-Monitor",
        "Web-Stat-Compression"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    BitLockerAdmin
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "RSAT-Feature-Tools-BitLocker",
        "RSAT-Feature-Tools-BitLocker-RemoteAdminTool",
        "RSAT-Feature-Tools-BitLocker-BdeAducExt"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    WEB
    {
        Write-Output "Adding Windows Features for $Role"
        $ServicesToInstall = @(
        "Web-Windows-Auth",
        "Web-ISAPI-Ext",
        "Web-Metabase",
        "Web-WMI",
        "NET-Framework-Features",
        "Web-Asp-Net",
        "Web-Asp-Net45",
        "NET-HTTP-Activation",
        "NET-Non-HTTP-Activ",
        "Web-Static-Content",
        "Web-Default-Doc",
        "Web-Dir-Browsing",
        "Web-Http-Errors",
        "Web-Http-Redirect",
        "Web-App-Dev",
        "Web-Net-Ext",
        "Web-Net-Ext45",
        "Web-ISAPI-Filter",
        "Web-Health",
        "Web-Http-Logging",
        "Web-Log-Libraries",
        "Web-Request-Monitor",
        "Web-HTTP-Tracing",
        "Web-Security",
        "Web-Filtering",
        "Web-Performance",
        "Web-Stat-Compression",
        "Web-Mgmt-Console",
        "Web-Scripting-Tools",
        "Web-Mgmt-Compat"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    Default
    {
        Write-Warning "Nothing to do for role $Role"
    }
    
}
