# Read Settings from XML
$SettingsFile = "\\cldepl01\ApplicationRoot\XML\FASettings.xml"
[xml]$Settings = Get-Content -Path $SettingsFile

$Server = $Settings.Fabric.Servers.Server | Where ID -EQ STOR05
$Server.Networkadapters.Networkadapter | Where ID -EQ NIC01
$Server.Networkadapters.Networkadapter | Where ID -EQ NIC02
$Server.Networkadapters.Networkadapter | Where ID -EQ NIC03
$Server.Networkadapters.Networkadapter | Where ID -EQ NIC04
$Server.NetworkTeams.Networkteam | Where ID -EQ TEAM01
