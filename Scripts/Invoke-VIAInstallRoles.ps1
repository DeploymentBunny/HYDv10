<#
.Synopsis
    Script for HYDV10
.DESCRIPTION
    Script for HYDV10
.EXAMPLE
    C:\Setup\Scripts\Install-VIARoles.ps1 -Role DEPL
.NOTES
    Created:	 2015-12-15
    Version:	 3.0

    Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

    Disclaimer:
    This script is provided "AS IS" with no warranties, confers no rights and 
    is not supported by the author.
.LINK
    http://www.deploymentbunny.com
#>

[cmdletbinding(SupportsShouldProcess=$True)]
Param
(
    $Role="None"
)

# Set Vars
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
#[xml]$Settings = Get-Content "$ScriptDir\Settings.xml"
$SOURCEROOT = "$SCRIPTDIR\Source"
$LANG = (Get-Culture).Name
$OSV = $Null
$ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE

#Import function library
Import-Module "$ScriptDir\VIAInstall.psm1" -ErrorAction Stop -WarningAction Stop

#Try to Import SMSTSEnv
. Import-SMSTSENV

#Start Transcript Logging
. Start-Logging

#Detect current OS Version
. Get-OSVersion -osv ([ref]$osv) 

#Output base info
Write-Output ""
Write-Output "$ScriptName - ScriptDir: $ScriptDir"
Write-Output "$ScriptName - SourceRoot: $SOURCEROOT"
Write-Output "$ScriptName - ScriptName: $ScriptName"
Write-Output "$ScriptName - OS Name: $osv"
Write-Output "$ScriptName - OS Architecture: $ARCHITECTURE"
Write-Output "$ScriptName - Current Culture: $LANG"
Write-Output "$ScriptName - Integration with MDT(LTI/ZTI): $MDTIntegration"
Write-Output "$ScriptName - Log: $LogFile"

#Generate more info
if($MDTIntegration -eq "YES"){
    $TSMake = $tsenv.Value("Make")
    $TSModel = $tsenv.Value("Model")
    $TSMakeAlias = $tsenv.Value("MakeAlias")
    $TSModelAlias = $tsenv.Value("ModelAlias")
    $TSOSDComputerName = $tsenv.Value("OSDComputerName")
    Write-Output "$ScriptName - Make:: $TSMake"
    Write-Output "$ScriptName - Model: $TSModel"
    Write-Output "$ScriptName - MakeAlias: $TSMakeAlias"
    Write-Output "$ScriptName - ModelAlias: $TSModelAlias"
    Write-Output "$ScriptName - OSDComputername: $TSOSDComputerName"
}

#Custom Code Starts--------------------------------------


switch ($Role)
{
    LABHOST
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "FS-FileServer",
        "Data-Center-Bridging",
        "Failover-Clustering",
        "FS-Data-Deduplication",
        "Hyper-V"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    S2D
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "FS-FileServer",
        "Data-Center-Bridging",
        "Failover-Clustering"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    Storage
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "FS-FileServer",
        "FS-Data-Deduplication",
        "FS-VSS-Agent",
        "Storage-Services",
        "Data-Center-Bridging",
        "Multipath-IO"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    Storageclu
    {
        Write-Output "Adding Windows Features for selected role: $Role"
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
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "Hyper-V"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    ComputeClu
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "Hyper-V",
        "Failover-Clustering"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    HyperConv
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "Hyper-V",
        "FS-FileServer",
        "Data-Center-Bridging",
        "Failover-Clustering"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
    }
    FILE
    {
        Write-Output "Adding Windows Features for selected role: $Role"
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
        Write-Output "Adding Windows Features for selected role: $Role"
        Install-WindowsFeature -Name "RDS-GateWay" -IncludeManagementTools -IncludeAllSubFeature -ErrorAction Stop
    }
    ADDS
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        Add-WindowsFeature -Name AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
    }
    DHCP
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        Add-WindowsFeature -Name DHCP -IncludeManagementTools
        Start-Sleep 2

    }
    RRAS
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        Install-WindowsFeature Routing -IncludeManagementTools
        Install-RemoteAccess -VpnType Vpn
    }
    RDGW
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        Install-WindowsFeature -Name RDS-GateWay -IncludeManagementTools -IncludeAllSubFeature
    }
    MGMT
    {
        Write-Output "Adding Windows Features for selected role: $Role"
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
        Write-Output "Adding Windows Features for selected role: $Role"
        Add-WindowsFeature -Name WDS -IncludeAllSubFeature -IncludeManagementTools
        Add-WindowsFeature -Name FS-FileServer,FS-Data-Deduplication
    }
    ADCA
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        Add-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools
    }
    WSUS
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "UpdateServices-Services",
        "UpdateServices-DB"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    WSUSIDB
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "UpdateServices-Services",
        "UpdateServices-DB"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    SCVM
    {
        Write-Output "Adding Windows Features for selected role: $Role"
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
        Write-Output "Adding Windows Features for selected role: $Role"
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
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "RSAT-Feature-Tools-BitLocker",
        "RSAT-Feature-Tools-BitLocker-RemoteAdminTool",
        "RSAT-Feature-Tools-BitLocker-BdeAducExt"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools
    }
    WEB
    {
        Write-Output "Adding Windows Features for selected role: $Role"
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

#Custom Code Ends--------------------------------------

. Stop-Logging