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

Function Get-VIAOSVersion([ref]$OSv){
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    Switch -Regex ($OS.Version)
    {
    "6.1"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 7 SP1"}
                Else
            {$OSv.value = "Windows Server 2008 R2"}
        }
    "6.2"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 8"}
                Else
            {$OSv.value = "Windows Server 2012"}
        }
    "6.3"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 8.1"}
                Else
            {$OSv.value = "Windows Server 2012 R2"}
        }
    "10"
        {If($OS.ProductType -eq 1)
            {$OSv.value = "Windows 10"}
                Else
            {$OSv.value = "Windows Server 2016"}
        }
    DEFAULT { "Version not listed" }
    } 
}
Function Import-VIASMSTSENV{
    try{
        $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
        Write-Output "$ScriptName - tsenv is $tsenv "
        $MDTIntegration = $true
        
        #$tsenv.GetVariables() | % { Write-Output "$ScriptName - $_ = $($tsenv.Value($_))" }
    }
    catch{
        Write-Output "$ScriptName - Unable to load Microsoft.SMS.TSEnvironment"
        Write-Output "$ScriptName - Running in standalonemode"
        $MDTIntegration = $false
    }
    Finally{
        if ($MDTIntegration -eq $true){
            $Logpath = $tsenv.Value("LogPath")
            $LogFile = $Logpath + "\" + "$ScriptName.txt"
        }
    Else{
            $Logpath = $env:TEMP
            $LogFile = $Logpath + "\" + "$ScriptName.txt"
        }
    }
    Return $MDTIntegration
}
Function Start-VIALogging{
    Start-Transcript -path $LogFile -Force
}
Function Stop-VIALogging{
    Stop-Transcript
}
Function Invoke-VIAExe{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Executable,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

    if($Arguments -eq "")
    {
        Write-Verbose "Running Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -NoNewWindow -Wait -Passthru
    }else{
        Write-Verbose "Running Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
        $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
    }
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
Function Invoke-VIAMsi{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MSI,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

    #Set MSIArgs
    $MSIArgs = "/i " + $MSI + " " + $Arguments

    if($Arguments -eq "")
    {
        $MSIArgs = "/i " + $MSI

        
    }
    else
    {
        $MSIArgs = "/i " + $MSI + " " + $Arguments
    
    }
    Write-Verbose "Running Start-Process -FilePath msiexec.exe -ArgumentList $MSIArgs -NoNewWindow -Wait -Passthru"
    $ReturnFromEXE = Start-Process -FilePath msiexec.exe -ArgumentList $MSIArgs -NoNewWindow -Wait -Passthru
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}
Function Invoke-VIAMsu{
    [CmdletBinding(SupportsShouldProcess=$true)]

    param(
        [parameter(mandatory=$true,position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MSU,

        [parameter(mandatory=$false,position=1)]
        [string]
        $Arguments
    )

        #Set MSIArgs
    $MSUArgs = $MSU + " " + $Arguments

    if($Arguments -eq "")
    {
        $MSUArgs = $MSU

        
    }
    else
    {
        $MSUArgs = $MSU + " " + $Arguments
    
    }

    Write-Verbose "Running Start-Process -FilePath wusa.exe -ArgumentList $MSUArgs -NoNewWindow -Wait -Passthru"
    $ReturnFromEXE = Start-Process -FilePath wusa.exe -ArgumentList $MSUArgs -NoNewWindow -Wait -Passthru
    Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
    Return $ReturnFromEXE.ExitCode
}

# Set Vars
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
#[xml]$Settings = Get-Content "$ScriptDir\Settings.xml"
$SOURCEROOT = "$SCRIPTDIR\Source"
$LANG = (Get-Culture).Name
$OSV = $Null
$ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE

#Try to Import SMSTSEnv
. Import-VIASMSTSENV

#Start Transcript Logging
. Start-VIALogging

#Detect current OS Version
. Get-VIAOSVersion -osv ([ref]$osv) 

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
        $ServicesToInstall = @(
        "AD-Domain-Services",
        "Windows-Server-Backup",
        "RSAT-DFS-Mgmt-Con"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
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
    SCDP
    {
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "Hyper-V-Tools",
        "Hyper-V-PowerShell"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
        
        $Executable = "dism.exe" 
        $Arguments = " /Online /Enable-feature /All /FeatureName:Microsoft-Hyper-V /FeatureName:Microsoft-Hyper-V-Management-PowerShell /quiet /norestart"
        Invoke-VIAExe -Executable $Executable -Arguments $Arguments
    }
    SCOR{
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
    'SCOM'{
        Write-Output "Adding Windows Features for selected role: $Role"
        $ServicesToInstall = @(
        "Web-Default-Doc",          
        "Web-Dir-Browsing",         
        "Web-Http-Errors",          
        "Web-Static-Content",       
        "Web-Http-Logging",         
        "Web-Request-Monitor",      
        "Web-Stat-Compression",     
        "Web-Filtering",            
        "Web-Windows-Auth",         
        "Web-Net-Ext",              
        "Web-Net-Ext45",            
        "Web-Asp-Net",              
        "Web-Asp-Net45",            
        "Web-CGI",                  
        "Web-ISAPI-Ext",            
        "Web-ISAPI-Filter",         
        "Web-Mgmt-Console",         
        "Web-Mgmt-Compat",          
        "Web-Metabase",             
        "NET-Framework-Core",       
        "NET-HTTP-Activation",      
        "NET-Framework-45-Core",    
        "NET-Framework-45-ASPNET",  
        "NET-WCF-Services45",       
        "NET-WCF-TCP-PortSharing45",
        "WAS-Process-Model",        
        "WAS-NET-Environment",      
        "WAS-Config-APIs"
        )
        Install-WindowsFeature -Name $ServicesToInstall -IncludeManagementTools -IncludeAllSubFeature
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

. Stop-VIALogging