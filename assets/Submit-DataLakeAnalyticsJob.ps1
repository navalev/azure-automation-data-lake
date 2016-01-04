#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
    $CredentialAssetName = 'DefaultAzureCredentials'

    #Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }

    #Connect to your Azure Account
    $Account = Login-AzureRmAccount -Credential $Cred
    if(!$Account) {
        Throw "Could not authenticate to Azure using the credential asset '${CredentialAssetName}'. Make sure the user name and password are correct."
    }

# submit the Data Lake Analytics job to execute the append script
$account = Get-AutomationVariable -Name 'dataLakeAccountName' 
$rg = Get-AutomationVariable -Name 'dataLakeResourceGroup'
$scriptName = Get-AutomationVariable -Name 'uSQLScript'
$script =  (new-object Net.WebClient).DownloadString($scriptName)
$date = Get-Date
	
Submit-AzureRmDataLakeAnalyticsJob -AccountName $account -Name "appendJob-$date" -ResourceGroupName $rg -Script $script