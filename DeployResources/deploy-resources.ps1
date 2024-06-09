# Creates the following new resources:
    # DEV, UAT and PROD resource groups
    # Creates a new Data Factory in the DEV resource group 
    # Creates 200 new Data Factory pipelines (35 Wait Activities in each pipeline) to create an overall ARM template over 4MB


# Resource Names and Config
$DEVResourceGroupName = 'rg-adf-cicd-linked'
$UATResourceGroupName = 'rg-adf-cicd-linked-uat'
$PRODResourceGroupName = 'rg-adf-cicd-linked-prod'
$DataFactoryName = 'adf-linked-templates-njl'
$DataFactoryPipelineDefinitionFileName = 'DataFactoryPipeline.json'
$Location = 'eastus'


# Create the DEV, UAT, PROD resource group names
# az group create --name $DEVResourceGroupName --location $Location # DEV
# az group create --name $UATResourceGroupName --location $Location # UAT
# az group create --name $PRODResourceGroupName --location $Location # PROD

# Create a Data Factory
az datafactory create --factory-name $DataFactoryName --resource-group $DEVResourceGroupName --location $Location


# Creates 200 new Data Factory pipelines (35 Wait Activities in each pipeline)
# Loops from 1 to 200 creating a pipeline named PL_WAIT_Number. Ex: PL_WAIT_1, PL_WAIT_2... PL_WAIT_200 
for ($i = 1; $i -le 10; $i++) {
    $PipelineName = "PL_WAIT_" + $i.ToString() # Ex: PL_WAIT_1
    
    # Creates the new Data Factory Pipeline using the 35 Wait Activity JSON file DataFactoryPipeline.json
    az datafactory pipeline create --factory-name $DataFactoryName --pipeline $DataFactoryPipelineDefinitionFileName --name $PipelineName --resource-group $DEVResourceGroupName
}


# To cleanup and delete everything above
# az group delete --name $DEVResourceGroupName
# az group delete --name $UATResourceGroupName
# az group delete --name $PRODResourceGroupName