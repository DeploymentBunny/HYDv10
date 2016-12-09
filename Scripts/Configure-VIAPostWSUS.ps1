<#
Created:	 2013-01-08
Version:	 1.0
Author       Mikael Nystrom and Johan Arwidmark       
Homepage:    http://www.deploymentfundamentals.com

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the authors or DeploymentArtist.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com

Author - Johan Arwidmark
    Twitter: @jarwidmark
    Blog   : http://deploymentresearch.com
#>

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
    Write-Output "Still syncing"            
    Start-Sleep -Seconds 5            
} 

# Set WSUS Classifications
# Run "Get-WsusClassification" to get the Names and IDs
Get-WsusClassification | Where-Object –FilterScript {$_.Classification.Id -Eq "cd5ffd1e-e932-4e3a-bf74-18bf0b1bbd83"} | Set-WsusClassification #Updates
Get-WsusClassification | Where-Object –FilterScript {$_.Classification.Id -Eq "e6cf1350-c01b-414d-a61f-263d14d133b4"} | Set-WsusClassification #Critical Updates
Get-WsusClassification | Where-Object –FilterScript {$_.Classification.Id -Eq "0fa1201d-4330-4fa8-8ae9-b877473b6441"} | Set-WsusClassification #Security Updates
Get-WsusClassification | Where-Object –FilterScript {$_.Classification.Id -Eq "e0789628-ce08-4437-be74-2495b842f43b"} | Set-WsusClassification #Definition Updates
Get-WsusClassification | Where-Object –FilterScript {$_.Classification.Id -Eq "68c5b0a3-d1a6-4553-ae49-01d3a7827828"} | Set-WsusClassification #Service Packs

# Set WSUS Products
# Run "Get-WsusProduct" to get all products
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "9f3dd20a-1004-470e-ba65-3dc62d982958"} | Set-WsusProduct #Silverlight 
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "8c3fcc84-7410-4a95-8b89-a166a0190486"} | Set-WsusProduct #Windows Defender
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "48ce8c86-6850-4f68-8e9d-7dc8535ced60"} | Set-WsusProduct #Developer Tools, Runtimes, and Redistributables
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "e903c733-c905-4b1c-a5c4-3528b6bbc746"} | Set-WsusProduct #Microsoft Azure Site Recovery Provider                              
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "23b3da8b-060e-4517-a431-3cb10f040794"} | Set-WsusProduct #Microsoft Azure                                    
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "c0ca76d3-e3af-42cd-bf0f-47bcc0ff797f"} | Set-WsusProduct #Windows Azure Pack - Web Sites                                    
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "1aea70f3-d989-4f89-9055-b0bc9945b75f"} | Set-WsusProduct #Windows Azure Pack: Admin API                                    
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "983dabe5-e68d-4cb3-ae5e-6da88e66783f"} | Set-WsusProduct #Windows Azure Pack: Admin Authentication Site                                     
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "2f1d3c10-1e92-487b-baba-2c1c645367b9"} | Set-WsusProduct #Windows Azure Pack: Admin Site
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "57869cb9-cd47-4ce4-acd5-caf49a0c713f"} | Set-WsusProduct #Windows Azure Pack: Configuration Site
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "6102ab07-dd96-4407-8c82-2f2db7022248"} | Set-WsusProduct #Windows Azure Pack: Microsoft Best Practice Analyzer
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "10b00347-cd06-41fd-b7ba-32200693e114"} | Set-WsusProduct #Windows Azure Pack: Monitoring Extension
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "71debf20-7fce-4e93-8a6c-4a3fad0313ec"} | Set-WsusProduct #Windows Azure Pack: MySQL Extension
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "19243b1e-a4c1-4e87-80f4-fa8546ce4489"} | Set-WsusProduct #Windows Azure Pack: PowerShell API
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "8516af00-35dc-4fd6-af4f-e1a9f117a882"} | Set-WsusProduct #Windows Azure Pack: SQL Server Extension
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "2c25d763-d623-433f-b956-0de582e32b19"} | Set-WsusProduct #Windows Azure Pack: Tenant API
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "45afcceb-93c4-4ac3-909c-ca349acbc264"} | Set-WsusProduct #Windows Azure Pack: Tenant Authentication Site
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "3f50dcc0-6199-4ae0-a166-6d87d4e6f83e"} | Set-WsusProduct #Windows Azure Pack: Tenant Public API
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "95a5f8e0-f2ab-4be6-bc4a-34d4b790192f"} | Set-WsusProduct #Windows Azure Pack: Tenant Site
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "9e185861-6465-41db-83c4-bb1480a55851"} | Set-WsusProduct #Windows Azure Pack: Usage Extension
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "5c91542d-b573-44e9-a86d-b13b27cd98db"} | Set-WsusProduct #Windows Azure Pack: Web App Gallery Extension
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "3c9e83e3-614d-4670-9205-cfcf3ea62a29"} | Set-WsusProduct #Windows Azure Pack: Web Sites
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "bd282a5b-d44a-4ef0-9bba-2b9ad8b7c99e"} | Set-WsusProduct #Windows Azure Pack
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "e54f3c9b-eec3-48f4-a791-ef1e2b0586d0"} | Set-WsusProduct #System Center 2012 R2 - Data Protection Manager
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "2a9170d5-3434-4820-885c-61a4f3fc6f84"} | Set-WsusProduct #System Center 2012 R2 - Operations Manager
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "6ddf2e90-4b40-471c-a664-6cd6b7e0d0a7"} | Set-WsusProduct #System Center 2012 R2 - Orchestrator
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "8a3485af-4301-43e1-b2d9-f9ddb7576125"} | Set-WsusProduct #System Center 2012 R2 - Virtual Machine Manager
Get-WsusProduct | Where-Object –FilterScript {$_.Product.ID -Eq "d31bd4c3-d872-41c9-a2e7-231f372588cb"} | Set-WsusProduct #Windows Server 2012 R2

#Set Sync Auto
$WSUSSrvSubScrip = $WSUSSrv.GetSubscription()
$WSUSSrvSubScrip.SynchronizeAutomatically=$True

#Note: The time is in GMT
$WSUSSrvSubScrip.SynchronizeAutomaticallyTimeOfDay="20:00:00"
$WSUSSrvSubScrip.NumberOfSynchronizationsPerDay="3"
$WSUSSrvSubScrip.Save()

# Synchronization
$WSUSSrvSubScrip = $WSUSSrv.GetSubscription()
$WSUSSrvSubScrip.StartSynchronization()
While($WSUSSrvSubScrip.GetSynchronizationStatus() -ne 'NotProcessing') 
{            
    Write-Host "Still syncing"            
    Start-Sleep -Seconds 5            
} 

#Decline superseeded updates
$SuperSeededUpdates = Get-WsusUpdate -Approval AnyExceptDeclined -Classification All -Status Any | Where-Object -Property UpdatesSupersedingThisUpdate -NE -Value 'None'
$SuperSeededUpdates | Deny-WsusUpdate

#Create the Default Approvel Rule
$CategoryCollection = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
$ClassificationCollection = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
$TargetgroupCollection = New-Object Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection
$ApprovalRule = "Fabric Default Rule"
$UpdateCategories = "Windows Server 2012 R2|Windows Defender|Visual Studio 2005|Visual Studio 2008|Visual Studio 2010|Visual Studio 2012|Windows Azure Pack"
$UpdateClassifications = "Critical Updates|Security Updates|Definition Updates"
$ComputerTargetGroup = "All Computers"

$NewRule = $WSUSSrv.CreateInstallApprovalRule($ApprovalRule)
$UpdateCategories = $WSUSSrv.GetUpdateCategories() | Where {  $_.Title -Match $UpdateCategories}
$CategoryCollection.AddRange($updateCategories)
$NewRule.SetCategories($categoryCollection)
$UpdateClassifications = $WSUSSrv.GetUpdateClassifications() | Where { $_.Title -Match $UpdateClassifications}
$ClassificationCollection.AddRange($updateClassifications )
$NewRule.SetUpdateClassifications($classificationCollection)
$TargetGroups = $WSUSSrv.GetComputerTargetGroups() | Where {$_.Name -Match $ComputerTargetGroup}
$TargetgroupCollection.AddRange($targetGroups)
$NewRule.SetComputerTargetGroups($targetgroupCollection)
$NewRule.Enabled = $True
$NewRule.Save()
$NewRule.ApplyRule()
