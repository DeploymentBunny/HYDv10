#Run WSUS MetaData Sync
$WSUSSrv = Get-WSUSServer -Name localhost -Port 8530
$WSUSSrvCFG = $WSUSSrv.GetConfiguration()
$WSUSSrvSubScrip = $WSUSSrv.GetSubscription()

#Set WSUS to download from MU
Set-WsusServerSynchronization -SyncFromMU

# Choose Languages
$WSUSSrvCFG = $WSUSSrv.GetConfiguration()
$WSUSSrvCFG.AllUpdateLanguagesEnabled = $false
$WSUSSrvCFG.AllUpdateLanguagesDssEnabled = $false
$WSUSSrvCFG.SetEnabledUpdateLanguages("en")
$WSUSSrvCFG.Save()

# Remove All Products and Classifications
Get-WsusClassification | Set-WsusClassification -Disable
Get-WsusProduct | Set-WsusProduct -Disable

# Run the initial Configuration (No Downloads)
$WSUSSrvSubScrip = $WSUSSrv.GetSubscription()
$WSUSSrvSubScrip.StartSynchronizationForCategoryOnly()            
While($WSUSSrvSubScrip.GetSynchronizationStatus() -ne 'NotProcessing') 
{            
    Write-Warning "Still syncing"            
    Start-Sleep -Seconds 5            
}