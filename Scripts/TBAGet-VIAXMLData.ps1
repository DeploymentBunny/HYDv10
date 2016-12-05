Function Get-VIAXMLData{
<#
    Get-VIAXMLData -VIAXMLdataFile C:\Setup\HYDv10\Settings\ViaMonstra\FASettings.xml
    [XML]$XMLData = Get-Content -Path C:\Setup\HYDv10\Settings\ViaMonstra\FASettings.xml
    $Networks = $XMLData.Fabric.Networks
#>
    Param(
        $VIAXMLdataFile
    )
    [XML]$XMLData = Get-Content -Path $VIAXMLdataFile
    $Version = $XMLData.Fabric.Version
    $Customer = $XMLData.Fabric.Customer
    $Global = $XMLData.Fabric.Global
    $Networks = $XMLData.Fabric.Networks
    $Domain = $XMLData.Fabric.Domain
    $DomainAccounts = $XMLData.Fabric.DomainAccounts
    $DomainOUs = $XMLData.Fabric.DomainOUs
    $DomainGroups = $XMLData.Fabric.DomainGroups
    $ProductKeys = $XMLData.Fabric.ProductKeys

    Write-Host "Solution            : $($Version.Solution) Version:$($Version.MajorVersion).$($Version.MinorVersion)" -ForegroundColor Cyan 
    Write-Host "Customer Name       : $($Customer.Name)" -ForegroundColor Cyan 
    Write-Host "Contact             : $($Customer.Contact)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "LocalPassword       : $($Global.LocalPassword)" -ForegroundColor Cyan
    Write-Host "OrgName             : $($Global.OrgName)" -ForegroundColor Cyan
    Write-Host "FullName            : $($Global.FullName)" -ForegroundColor Cyan
    Write-Host "TimeZoneName        : $($Global.TimeZoneName)" -ForegroundColor Cyan
    Write-Host "InputLocale         : $($Global.InputLocale)" -ForegroundColor Cyan
    Write-Host "SystemLocale        : $($Global.SystemLocale)" -ForegroundColor Cyan
    Write-Host "UILanguage          : $($Global.UILanguage)" -ForegroundColor Cyan
    Write-Host "UserLocale          : $($Global.UserLocale)" -ForegroundColor Cyan
    Write-Host "VMSwitchName        : $($Global.VMSwitchName)" -ForegroundColor Cyan
    Write-Host "WorkgroupName       : $($Global.WorkgroupName)" -ForegroundColor Cyan
    Write-Host "VHDSize (MB)        : $($Global.VHDSize)" -ForegroundColor Cyan
    Write-Host ""

    foreach($network in $Networks.Network){
        Write-Host "Network Name        : $($network.Name)" -ForegroundColor Green
        Write-Host "Network IP          : $($network.NetIP)" -ForegroundColor Green
        Write-Host "Network Subnet      : $($network.SubNet)" -ForegroundColor Green
        Write-Host "Network Gateway     : $($network.Gateway)" -ForegroundColor Green
        Write-Host "Network DNS         : $($network.DNS)" -ForegroundColor Green
        Write-Host "Network DHCP        : $($network.DHCPStart) - $($network.DHCPEnd)" -ForegroundColor Green
        Write-Host "Network SCVMM       : $($network.VMMStart) - $($network.VMMEnd)" -ForegroundColor Green
        Write-Host "VLAN                : $($network.VLAN)" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "DNSDomain           : $($Domain.DNSDomain)" -ForegroundColor Cyan
    Write-Host "DomainNetBios       : $($Domain.DomainNetBios)" -ForegroundColor Cyan
    Write-Host "DomainAdmin         : $($Domain.DomainAdmin)" -ForegroundColor Cyan
    Write-Host "DomainAdminPassword : $($Domain.DomainAdminPassword)" -ForegroundColor Cyan
    Write-Host "DomainAdminDomain   : $($Domain.DomainAdminDomain)" -ForegroundColor Cyan
    Write-Host "DomainDS            : $($Domain.DomainDS)" -ForegroundColor Cyan
    Write-Host "ExternalCertName    : $($Domain.ExternalCertName)" -ForegroundColor Cyan
    Write-Host "ExternalCertPw      : $($Domain.ExternalCertPw)" -ForegroundColor Cyan
    Write-Host "ExternalDNSDomain   : $($Domain.ExternalDNSDomain)" -ForegroundColor Cyan
    Write-Host "MachienObjectOU     : $($Domain.MachienObjectOU)" -ForegroundColor Cyan
    Write-Host "SiteName            : $($Domain.SiteName)" -ForegroundColor Cyan
    Write-Host "BaseOU              : $($Domain.BaseOU)" -ForegroundColor Cyan

    foreach($DomainAccount in $DomainAccounts.DomainAccount){
        Write-Host "Name                : $($DomainAccount.Name)" -ForegroundColor Green
        Write-Host "Network IP          : $($DomainAccount.AccountDescription)" -ForegroundColor Green
        Write-Host ""
    }
}





Get-VIAXMLData -VIAXMLdataFile C:\Setup\HYDv10\Settings\ViaMonstra\FASettings.xml



[XML]$XMLData = Get-Content -Path C:\Setup\HYDv10\Settings\ViaMonstra\FASettings.xml
$Fabric = $XMLData.Fabric
$Customer = $XMLData.Fabric.Customers.Customer | Where-Object ID -EQ Customer
$CommonSetting = $XMLData.Fabric.CommonSettings.CommonSetting  | Where-Object ID -EQ CommonSetting
$Domain = $XMLData.Fabric.Domains.Domain   | Where-Object ID -EQ Domain
$DomainAccounts = $XMLData.Fabric.DomainAccounts
$DomainOUs = $XMLData.Fabric.DomainOUs
$DomainGroups = $XMLData.Fabric.DomainGroups
$ProductKeys = $XMLData.Fabric.ProductKeys
$Networks = $XMLData.Fabric.Networks
$Servers = $XMLData.Fabric.Servers
$Certificates = $XMLData.Fabric.Certificates

$Customer.Name
$Customer.Contact
$CommonSetting
$Domain

$DomainAccounts.DomainAccount | FT
$DomainOUs.DomainOU | FT
$DomainGroups.DomainGroup | FT
$ProductKeys.ProductKey | FT
$Networks.Network | FT
$Certificates.Certificate | FT

foreach($Server in ($Servers.Server)){
    $Server.Name
    $Server.Settings
    $Server.OperatingSystem
    $Server.OOBConfiguration
    $Server.Networkadapters
    $Server.NetworkTeams
}


$Servers.Server

$Role = $XMLData.Fabric.Roles.Role | Where-Object -Property Name -EQ -Value FDC
foreach($Task in ($Role.Tasks.task)){
    Invoke-Expression -Command $Task.Command
}

