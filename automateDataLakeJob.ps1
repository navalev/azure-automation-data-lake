
#Connect to your Azure account
Login-AzureRmAccount

#Select your subscription if you have more than one
Select-AzureRmSubscription -SubscriptionId <subscription id>

$resourceGroup = "Automation-Group01"
$location = "West Europe"
$storageAccount = "autteststore0123987"
$container = "automation"

#create resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

#create storage account and container 
New-AzureRmStorageAccount -Name $storageAccount -Location $location -ResourceGroupName $resourceGroup -Type Standard_LRS
$storageKey = Get-AzureRmStorageAccountKey -Name $storageAccount -ResourceGroupName $resourceGroup
$ctx = New-AzureStorageContext  –StorageAccountName $storageAccount -StorageAccountKey $storageKey.key1
New-AzureStorageContainer -Name $container -Permission Container -Context $ctx

#upload scripts and data to the container
$module = Set-AzureStorageBlobContent -File "assets/AzureRM.DataLakeAnalytics.zip" -Container $container -Blob "AzureRM.DataLakeAnalytics.zip" -Context $ctx
$jobScript = Set-AzureStorageBlobContent -File "assets/Submit-DataLakeAnalyticsJob.ps1" -Container $container -Blob "Submit-DataLakeAnalyticsJob.ps1" -Context $ctx
$usql = Set-AzureStorageBlobContent -File "assets/appendQuery.usql" -Container $container -Blob "append.usql" -Context $ctx

$automationAccount = "AutomationAccountTest"

#Set the parameter values for the template
$Params = @{
    accountName = $automationAccount;
    regionId = $location;
	userName = "<automation ADD user name>"; 
	password = "<sutomation ADD password>";
    scriptUri = $jobScript.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri;
    moduleUri = $module.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri;
    uSQLScript = $usql.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri;
    dataLakeAccountName = "<data lake account name>";
    dataLakeResourceGroup =  "<data lake resource group>";
}

#create a new automation account with run book
New-AzureRmResourceGroupDeployment -Name Automationdeployment -ResourceGroupName $resourceGroup -TemplateFile "automationAccountDeployment.json" -TemplateParameterObject $Params

# create a webhook in the runbook. Make sure to store the webhook URI - you will not be able to extract it later!!!!
# Use this webhook uri to call the runbook from an Azure scheduler 
$webHookURI = (New-AzureRmAutomationWebhook -AutomationAccountName $automationAccount -ExpiryTime 10/2/2016 -IsEnabled $true -Name ScheduleWebHook -ResourceGroupName $resourceGroup -RunbookName Submit-DataLakeAnalyticsJob).WebhookURI

#Connect to your Azure account
Add-AzureAccount

#Select your subscription if you have more than one
Select-AzureSubscription -SubscriptionId <subscription id>

#create scheduler to execute the automation job via the webhook
$jobCollectionName = "Scheduler_Test_01"
New-AzureSchedulerJobCollection -JobCollectionName $jobCollectionName -Location $location -Frequency Minute -Interval 10 -Plan Standard
New-AzureSchedulerHttpJob -JobCollectionName $jobCollectionName -JobName Append -Location $location -Method POST -URI $webHookURI -StartTime 10/1/2016 -Frequency Minute -Interval 10
