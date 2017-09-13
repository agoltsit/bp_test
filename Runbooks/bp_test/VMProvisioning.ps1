#Login to azure Account
param(
 
 [string]
 $subscriptionId='9abfdea3-bf30-4d59-bc67-7a3dfa22309f',

 [string]
 $resourceGroupName = 'BPV-DevTest-Internal',

 [string]
 $deploymentName ='autodeployment',

 [string]
 $vmnode = "BP-WEBDEV3-A",

 [string]
 $templateFilePath = "https://raw.githubusercontent.com/arnisgolt/bp_test/master/websrvtemp1.json",

 [string]
 $parametersFilePath = "https://raw.githubusercontent.com/arnisgolt/bp_test/master/BP-DevOpsT-A-Vparameters.json",

 [String]
 $NodeConfigurationName="DefaultConfigurationWEBv2.localhost"
)

#parameter and configuration template files for deployment
#$paramFiles = Get-ChildItem -Path "$parametersFilePath" $newVMname.json ## this part need to test 

    Function RegisterRP {
        Param(
                [string]$ResourceProviderNamespace
            )

            Write-Host "Registering resource provider '$ResourceProviderNamespace'";
            Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
        }

$ErrorActionPreference = "Stop"


## credentials on azure as Azureservice
    
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    
    Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID `
    -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint


#select subscription

    Select-AzureRmSubscription -SubscriptionID $subscriptionId;


# Register RPs
$resourceProviders = @("microsoft.compute","microsoft.network");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)

        {
            Write-Host "Resource group '$resourceGroupName' does not exist. Scritpt is stopped." Exit;
        }

else{
    Write-Host "The resource group '$resourceGroupName' exist and continue to deploeyment VM ";
}

# Start the deployment
Write-Host "Starting deployment...";


New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName `
  -TemplateUri $templateFilePath `
  -TemplateParameterUri $parametersFilePath


  #registry the created VM to powershell DSC Account

  Register-AzureRmAutomationDscNode -AutomationAccountName 'system-update' -AzureVMName $vmnode -ResourceGroupName $resourceGroupName -NodeConfigurationName $NodeConfigurationName `
    -AllowModuleOverwrite $true -RebootNodeIfNeeded $true
