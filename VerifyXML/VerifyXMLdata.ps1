$Global:SettingsFile = "C:\Setup\FABuilds\FASettings.xml"
Import-Module -Global C:\Setup\Functions\VIAXMLUtility.psm1 -Force


$CustomersData = Foreach($Item in (Get-VIAXMLFabricData -Class Customers)){
    Get-VIAXMLFabricCustomer -id $Item.id
}

$CustomersData
$CustomersData | Out-GridView

$CommonSettingsData = Foreach($Item in Get-VIAXMLFabricData -Class CommonSettings){
    Get-VIAXMLFabricCommonSetting -id $Item.id
}

$CommonSettingsData
$CommonSettingsData | Out-GridView

$ProductKeysData = Foreach($Item in Get-VIAXMLFabricData -Class ProductKeys){
    Get-VIAXMLFabricProductKey -id $Item.id
}

$ProductKeysData
$ProductKeysData | Out-GridView

$FabricNetworkData = Foreach($Item in Get-VIAXMLFabricData -Class Networks){
    Get-VIAXMLFabricNetwork -id $Item.id
}

$FabricNetworkData
$FabricNetworkData | Out-GridView

$FabricDomainData = Foreach($Item in Get-VIAXMLFabricData -Class Domains){
    Get-VIAXMLFabricDomain -id $Item.id
}

$FabricDomainData
$FabricDomainData | Out-GridView

$FabricDomainOUData = Foreach($Item in Get-VIAXMLFabricData -Class Domains){
    Get-VIAXMLFabricDomainOU -id $Item.id
}

$FabricDomainOUData
$FabricDomainOUData | Out-GridView

$FabricDomainAccountData = Foreach($Item in Get-VIAXMLFabricData -Class Domains){
    Get-VIAXMLFabricDomainAccount -id $Item.id
}

$FabricDomainAccountData
$FabricDomainAccountData | Out-GridView


$FabricDomainGroupData = Foreach($Item in Get-VIAXMLFabricData -Class Domains){
    Get-VIAXMLFabricDomainGroup -id $Item.id
}

$FabricDomainGroupData
$FabricDomainGroupData | Out-GridView

$FabricDomainCertificate = Foreach($Item in Get-VIAXMLFabricData -Class Domains){
    Get-VIAXMLFabricDomainCertificate -id $Item.id
}

$FabricDomainCertificate
$FabricDomainGroupData | Out-GridView

$FabricServerData = Foreach($Item in Get-VIAXMLFabricData -Class Servers){
    Get-VIAXMLFabricServer -id $Item.id
}

$FabricServerData
$FabricServerData | Out-GridView

$FabricServerRoleData = Foreach($Item in Get-VIAXMLFabricData -Class Servers){
    Get-VIAXMLFabricServerRole -id $Item.id
}

$FabricServerRoleData
$FabricServerRoleData | Out-GridView

$FabricServerOptionalSettingData = Foreach($Item in Get-VIAXMLFabricData -Class Servers){
    Get-VIAXMLFabricServerOptionalSetting -id $Item.id
}

$FabricServerOptionalSettingData
$FabricServerOptionalSettingData | Out-GridView

$FabricServerNetworkadapter = Foreach($Item in Get-VIAXMLFabricData -Class Servers){
    Get-VIAXMLFabricServerNetworkadapter -id $Item.id
}

$FabricServerNetworkadapter
$FabricServerNetworkadapter | Out-GridView

$FabricServerNetworkTeam = Foreach($Item in Get-VIAXMLFabricData -Class Servers){
    Get-VIAXMLFabricServerNetworkTeam -id $Item.id
}

$FabricServerNetworkTeam
$FabricServerNetworkTeam | Out-GridView

$FabricServerDataDisk = Foreach($Item in Get-VIAXMLFabricData -Class Servers){
    Get-VIAXMLFabricServerDataDisk -id $Item.id
}

$FabricServerDataDisk
$FabricServerDataDisk | Out-GridView

$FabricCertificate = Foreach($Item in Get-VIAXMLFabricData -Class Certificates){
    Get-VIAXMLFabricCertificate -id $Item.id
}

$FabricCertificate
$FabricCertificate | Out-GridView

$FabricVHD = Foreach($Item in Get-VIAXMLFabricData -Class VHDs){
    Get-VIAXMLFabricVHD -id $Item.id
}

$FabricVHD
$FabricVHD | Out-GridView

$FabricRoles = Foreach($Item in Get-VIAXMLFabricData -Class Roles){
    Get-VIAXMLFabricRoles -id $Item.id
}

$FabricRoles
$FabricRoles | Out-GridView
($FabricRoles | Where-Object -Property Name -EQ -Value FDC).config
(($FabricRoles | Where-Object -Property Name -EQ -Value FDC).config | Where-Object Name -EQ Sample01).'#text'

$FabricServices = Foreach($Item in Get-VIAXMLFabricData -Class Services){
    Get-VIAXMLFabricServices -id $Item.id
}

$FabricServices
$FabricServices | Out-GridView
$FabricServices | Where-Object -Property Name -EQ -Value SCDP2016
($FabricServices | Where-Object -Property Name -EQ -Value SCDP2016).config
(($FabricServices | Where-Object -Property Name -EQ -Value SCDP2016).config | Where-Object Name -EQ SQLINSTANCENAME).'#text'
(($FabricServices | Where-Object -Property Name -EQ -Value SCDP2016).config | Where-Object Name -EQ SQLINSTANCEDIR).'#text'
