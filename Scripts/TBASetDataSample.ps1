# Read Settings from XML
$SettingsFile = "\\cldepl01\ApplicationRoot\XML\FASettings.xml"
[xml]$Settings = Get-Content -Path $SettingsFile

$Server = $Settings.Fabric.Servers.Server | Where ID -EQ STOR05
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC01).MACAddress = "EC:B1:D7:84:B2:00"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC01).Name = "MGMT01"

$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC02).MACAddress = "EC:B1:D7:84:B2:01" 
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC02).Name = "MGMT02" 

$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).MACAddress = "68:05:CA:39:5C:98"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).Name = "SMB204"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).IPAddress = "172.16.204.88"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).PrefixLength = "24"

$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).MACAddress = "68:05:CA:39:5C:99"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).Name = "SMB205"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).IPAddress = "172.16.205.88"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).PrefixLength = "24"

$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).Name = "TEAM01"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).IPAddress = "172.16.200.91"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).PrefixLength = "24"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).DefaultGateway = "172.16.200.1"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).DNSServer01 = "172.16.200.21"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).DNSServer02 = "172.16.200.22"

$Settings.Save($SettingsFile)
[xml]$Settings = Get-Content -Path $SettingsFile

$Server = $Settings.Fabric.Servers.Server | Where ID -EQ STOR06
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC01).MACAddress = "C4:34:6B:B7:C0:44"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC01).Name = "MGMT01"

$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC02).MACAddress = "C4:34:6B:B7:C0:45" 
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC02).Name = "MGMT02" 

$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).MACAddress = "68:05:CA:39:5E:0C"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).Name = "SMB204"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).IPAddress = "172.16.204.89"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC03).PrefixLength = "24"

$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).MACAddress = "68:05:CA:39:5E:0D"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).Name = "SMB205"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).IPAddress = "172.16.205.89"
$($Server.Networkadapters.Networkadapter | Where ID -EQ NIC04).PrefixLength = "24"

$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).Name = "TEAM01"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).IPAddress = "172.16.200.92"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).PrefixLength = "24"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).DefaultGateway = "172.16.200.1"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).DNSServer01 = "172.16.200.21"
$($Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01).DNSServer02 = "172.16.200.22"

$Settings.Save($SettingsFile)
[xml]$Settings = Get-Content -Path $SettingsFile

