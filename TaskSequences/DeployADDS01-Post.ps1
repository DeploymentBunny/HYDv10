[cmdletbinding(SupportsShouldProcess=$true)]
Param
(
    [parameter(position=0,mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string]
    $SettingsFile = "C:\Setup\FABuilds\FASettings.xml",

    [parameter(Position=1,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VHDImage = "C:\Setup\VHD\WS2016-DCE_UEFI.vhdx",
    
    [parameter(Position=2,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [String]
    $VMlocation = "D:\VMs",

    [parameter(Position=3,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogPath = $LogPath,

    [parameter(Position=4,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Roles,

    [parameter(Position=5,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Server,

    [parameter(Position=6,mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [String]
    $FinishAction,

    [parameter(Position=7,mandatory=$False)]
    [Switch]
    $KeepMountedMedia
)

##############

#Init
$Server = "ADDS01"
$ROle = "ADDS"
$Global:LogPath= "$env:TEMP\log.txt"

#Set start time
$StartTime = Get-Date

#Step Step
$Step = 0

#Import Modules
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

#Set Values
$ServerName = $Server
$DomainName = "Fabric"

#Action
$Step = 1 + $step
$Action = "Notify start"
$Data = "Server:$ServerName" + "," + "Step:$Step" + "," + "Action:$Action"
Update-VIALog -Data $Data
Start-VIASoundNotify

#Read data from XML
$Step = 1 + $step
$Action = "Reading $SettingsFile"
$Data = "Server:$ServerName" + "," + "Step:$Step" + "," + "Action:$Action"
Update-VIALog -Data $Data
[xml]$Settings = Get-Content $SettingsFile -ErrorAction Stop
$CustomerData = $Settings.FABRIC.Customers.Customer
$CommonSettingData = $Settings.FABRIC.CommonSettings.CommonSetting
$ProductKeysData = $Settings.FABRIC.ProductKeys.ProductKey
$NetworksData = $Settings.FABRIC.Networks.Network
$ServicesData = $Settings.FABRIC.Services.Service
$DomainData = $Settings.FABRIC.Domains.Domain | Where-Object -Property Name -EQ -Value $DomainName
$ServerData = $Settings.FABRIC.Servers.Server | Where-Object -Property Name -EQ -Value $ServerName

$NIC01 = $ServerData.Networkadapters.Networkadapter | Where-Object -Property Name -EQ -Value NIC01
$NIC01RelatedData = $NetworksData | Where-Object -Property ID -EQ -Value $NIC01.ConnectedToNetwork

$AdminPassword = $CommonSettingData.LocalPassword
$DomainInstaller = $DomainData.DomainAdmin
$DomainName = $DomainData.DomainAdminDomain
$DNSDomain = $DomainData.DNSDomain
$DomainAdminPassword = $DomainData.DomainAdminPassword
$domainCred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$($domainName)\Administrator", (ConvertTo-SecureString $domainAdminPassword -AsPlainText -Force)


#Action
$Action = "Redirect New ComputerObject to OU"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Start-Process -FilePath "$ENV:SystemRoot\system32\redircmp.exe" -argumentlist (Get-ADOrganizationalUnit -Filter { Name -like 'Unassigned Servers' }).DistinguishedName
} -Credential $domainCred 


#Action
$Action = "Add KDS Root Key for Group Managed Service Accounts"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    $KDSKey = Get-KdsRootKey
    if ($KDSKey -eq $null) { Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10) } 
} -Credential $domainCred 

#Action
$Action = "Copy ADM/ADML Files to SYSVOL to Central Store"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Copy-Item -Path $ENV:SystemRoot\PolicyDefinitions\* $ENV:SystemRoot\SYSVOL\domain\Policies\PolicyDefinitions -Recurse -Force
} -Credential $domainCred 


#Action
$Action = "Setup DNS Scavenging "
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Set-DnsServerScavenging -ComputerName $ENV:COMPUTERNAME -ScavengingState $true
    Set-DnsServerScavenging -ApplyOnAllZones -ScavengingState $true 
} -Credential $domainCred 


#Action
$Action = "DHCP Server Conflict Detection Attempts"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Set-DhcpServerSetting -ConflictDetectionAttempts 1
} -Credential $domainCred 


#Action
$Action = "Securing DNSUpdateProxy Group"
#  DHCP: The DNSupdateproxy group must be secured if Name Protection is enabled on any IPv4 scope
#  https://technet.microsoft.com/en-us/library/ee941099%28v=ws.10%29.aspx 
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Start-Process -FilePath "$ENV:SystemRoot\system32\dnscmd.exe" -argumentlist "/config /OpenAclOnProxyUpdates 0" 
} -Credential $domainCred 


#Action
$Action = "Copy Script Files to SYSVOL"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Copy-Item -Path C:\Setup\HYDV10.Custom\Install-ADDS\Source\Sysvol\* $ENV:SystemRoot\SYSVOL\domain\scripts -Recurse -Force -Verbose

    $testnet = Test-NetConnection -CommonTCPPort HTTP -ComputerName live.sysinternals.com -InformationLevel Detailed
    if ($testnet.TcpTestSucceeded -eq $True) { 
    $Action = "Downloading latest version of BGInfo from Sysinternals"
    Update-VIALog -Data "Action: $Action"
    Invoke-WebRequest -Uri https://live.sysinternals.com/Bginfo.exe -OutFile $ENV:SystemRoot\SYSVOL\domain\scripts\BgInfo\bginfo.exe
    }

} -Credential $domainCred 



#Action
$Action = "Import WMI Filters"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {

    Invoke-Expression "C:\Setup\HYDV10.Custom\Install-GPOs\Script\Import-FAWMIFilters.ps1"

} -Credential $domainCred 



#Action
$Action = "Import Group Policy Objects"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {

Invoke-Expression "C:\Setup\HYDV10.Custom\Install-GPOs\Script\Import-FAGroupPolicies.ps1" 

} -Credential $domainCred 


#Action
$Action = "Set Default Password Policy"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Set-ADDefaultDomainPasswordPolicy -Identity $ENV:USERDNSDOMAIN -ComplexityEnabled $true -MinPasswordLength 15 -MinPasswordAge 0 -MaxPasswordAge 360 -LockoutDuration 00:30:00 -LockoutObservationWindow 00:30:00 -LockoutThreshold 10
    Get-ADDefaultDomainPasswordPolicy
} -Credential $domainCred 



#Action
$Action = "Check for GeoLocation"
Update-VIALog -Data "Action: $Action"

function get-myexternalip() {   
    $urls = "http://whatismyip.akamai.com",  
            "http://b10m.swal.org/cgi-bin/whatsmyip.cgi?just-ip",  
            "http://icanhazip.com",  
            "http://www.whatismyip.org/"; 
 
           $RxIP = "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"; 
           $ip = "Unknown"; 
           Foreach ($address in $urls) { 
               try { 
                    $temp = wget $address; 
                    $www_content = $temp.Content; 
                    if ( $www_content -match $RxIP ) { 
                        $ip = ([regex]($rxip)).match($www_content).Value 
                        break 
                    } 
               } catch { continue } 
           } 
    return $ip 
}


$CheckNetwork = Test-NetConnection -CommonTCPPort HTTP freegeoip.net
if ($CheckNetwork.TcpTestSucceeded -eq $True) { 
    $ExternalIP = (($Settings.FABRIC.Servers.Server | where Name -EQ "RRAS01").NetworkAdapters.Networkadapter | where ConnectedToNetwork -EQ "80c41589-c5fc-4785-a673-e8b08996cfc2").IPAddress
    [XML]$GeoLocation = Invoke-RestMethod -Method Get -Uri http://freegeoip.net/xml/$ExternalIP 
    $NTPGeolocation = $GeoLocation.Response.CountryCode.ToLower()
}


#Action
$Action = "Build NTP Pool Address"
Update-VIALog -Data "Action: $Action"
$NTPPool = "pool.ntp.org"
if ($NTPGeolocation -ne $Null) { $NTPPool = "$NTPGeolocation"+".pool.ntp.org,0x09 "+"$NTPPool"+",0x0a" } 


#Action
$Action = "Update NTP Settings for PDC GPO"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {
    Param($NTPPool)
     get-gpo -all | where DisplayName -like "*PDC*" | set-GPRegistryValue -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\W32time\Parameters" -ValueName NTPServer -Value "$NTPPool" -Type String
} -Credential $domainCred -ArgumentList $NTPPool 



#Action
$Action = "Update Various GPO Settings"
Update-VIALog -Data "Action: $Action"
Invoke-Command -VMName $($ServerData.ComputerName) -ScriptBlock {


    get-gpo -all | where DisplayName -like "*PDC*" | set-GPRegistryValue -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\W32time\Parameters" -ValueName NTPServer -Value "us.pool.ntp.org" -Type String

    # Replace Domain and Username 
    $GPO = get-gpo -all | where DisplayName -like "*PDC*"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml")
    $temp = $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") 
    $AdminUser = $env:USERDOMAIN+"\"+"Administrator"
    $temp = $temp.Replace("CLOUD\admmala","$AdminUser")
    $temp = $temp.Replace("CLOUD\","$env:USERDOMAIN\")
    $temp |Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml") -Force


    # Replace Domain and Username 
    $GPO = get-gpo -all | where DisplayName -like "*Fabric ScaleOutFileServers Settings - FSUTIL*"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml")
    $temp = $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") 
    $AdminUser = $env:USERDOMAIN+"\"+"Administrator"
    $temp = $temp.Replace("CLOUD\admmala","$AdminUser")
    $temp = $temp.Replace("CLOUD\","$env:USERDOMAIN\")
    $temp |Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml") -Force


    # Replace Domain and Username 
    $GPO = get-gpo -all | where DisplayName -like "*Fabric WebApplication Proxy - Default*"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml")
    $temp = $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") 
    $AdminUser = $env:USERDOMAIN+"\"+"Administrator"
    $temp = $temp.Replace("CLOUD\admmala","$AdminUser")
    $temp = $temp.Replace("CLOUD\","$env:USERDOMAIN\")
    $temp |Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml") -Force


    # Replace Domain and Username 
    $GPO = get-gpo -all | where DisplayName -like "*Fabric WSUS Servers Settings - Default*"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml")
    $temp = $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") 
    $AdminUser = $env:USERDOMAIN+"\"+"Administrator"
    $temp = $temp.Replace("CLOUD\admmala","$AdminUser")
    $temp = $temp.Replace("CLOUD\","$env:USERDOMAIN\")
    $temp |Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml") -Force


    # Replace Path in GPO's 
    $GPO = get-gpo -all | where DisplayName -like "*Fabric Computer Settings - Default*"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\Files\Files.xml")
    $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") | Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\Files\Files.xml") -Force


    # Replace Domain and Username
    $GPO = get-gpo -all | where DisplayName -like "*Fabric Application - Installation*"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml")
    $temp = $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") 
    $AdminUser = $env:USERDOMAIN+"\"+"Administrator"
    $temp = $temp.Replace("CLOUD\admmala","$AdminUser")
    $temp |Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml") -Force


    # Replace Domain and Username 
    $GPO = get-gpo -all | where DisplayName -like "Fabric Domain Controllers Settings - Default"
    $temp = get-content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml")
    $temp = $temp.Replace("cloud.truesec.com","$env:USERDNSDOMAIN") 
    $AdminUser = $env:USERDOMAIN+"\"+"Administrator"
    $temp = $temp.Replace("CLOUD\admmala","$AdminUser")
    $temp = $temp.Replace("CLOUD\","$env:USERDOMAIN\")
    $temp |Set-Content ("C:\Windows\SYSVOL\domain\Policies\"+"{"+$($GPO.id)+"}\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml") -Force


    # Change WSUS Computer Groups
    $GPOs = get-gpo -all | where DisplayName -like "*wsus*" 
    foreach ($GPO in $GPOs) {

        $WSUSSetting = Get-GPO -Name $GPO.DisplayName | Get-GPRegistryValue -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ValueName TargetGroup -ErrorAction SilentlyContinue
        if ($WSUSSetting.count -gt 0) { 
    
        Set-GPRegistryValue -Name $GPO.DisplayName -Key $WSUSSetting.FullKeyPath -ValueName $WSUSSetting.ValueName -Type String -Value ($WSUSSetting.Value).replace("Cloud","Fabric")
    
         }
    }

    # TBA : Fix Firewall rules 
    $GPOs = get-gpo -all | where DisplayName -like "*firewall*" 
    foreach ($GPO in $GPOs | select -first 1) {
        $Settings = Get-GPO -Name $GPO.DisplayName | Get-GPRegistryValue -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsFirewall\FirewallRules" -ErrorAction SilentlyContinue
        if ($WSUSSetting.count -gt 0) { 
    
    # TBA 
    # Change CLSCDP01 -> <real name>
    # Change IP to $SCOM01 (read from XML) 
    #
    # Repeat for SCOM and MGMT
    #
    # Replace 172.16.200 with real IP Range 
    #
    #    $Settings | foreach { Set-GPRegistryValue -Name $GPO.DisplayName -Key $_.FullKeyPath -ValueName $_.ValueName -Type String -Value ($_.Value).replace("172.16.200","172.16.0") }
    #    $Settings | foreach { Set-GPRegistryValue -Name $GPO.DisplayName -Key $_.FullKeyPath -ValueName $_.ValueName -Type String -Value ($_.Value).replace("172.16.200","172.16.0") }
    #    $Settings | foreach { Set-GPRegistryValue -Name $GPO.DisplayName -Key $_.FullKeyPath -ValueName $_.ValueName -Type String -Value ($_.Value).replace("172.16.200","172.16.0") }
    #    $Settings | foreach { Set-GPRegistryValue -Name $GPO.DisplayName -Key $_.FullKeyPath -ValueName $_.ValueName -Type String -Value ($_.Value).replace("172.16.200","172.16.0") }
         }
    }

} -Credential $domainCred 




#Action
$Action = "Done"
Write-Output "Action: $Action"
$Endtime = Get-Date
Update-VIALog -Data "The script took $(($Endtime - $StartTime).Days):Days $(($Endtime - $StartTime).Hours):Hours $(($Endtime - $StartTime).Minutes):Minutes to complete."




