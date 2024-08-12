# Creates the following new resources:
    # DEV, UAT and PROD resource groups
    # Creates a new Data Factory in the DEV resource group 
    # Creates 1000 new Data Factory pipelines (multiple wait activities created from the DataFactoryPipeline.json file) to create an overall ARM template over 4MB

    
# Helpful Links:
# https://learn.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-generate-sas
# https://andrewmatveychuk.com/how-to-deploy-linked-arm-templates-from-private-azure-devops-repositories/
# https://github.com/starkfell/100DaysOfIaC/blob/master/articles/day.42.deploy.nested.arm.templates.using.storage.accounts.in.yaml.pipeline.md?ref=andrewmatveychuk.com#1-preparing-the-arm-templates
# https://www.nathannellans.com/post/ci-cd-with-azure-data-factory-part-2
# https://github.com/nnellans/azure-data-factory/tree/main
# https://github.com/JFolberth/TheYAMLPipelineOne
# https://blog.johnfolberth.com/deploying-linked-arm-templates-via-yaml-pipelines/


# Prerequisites:
# - CD into the DeployResources folder. Ex: cd DeployResources
# - Update the variable name values below ($DEVResourceGroupName, etc.) 

# Resource Names and Config
$DEVResourceGroupName = 'rg-adf-cicd-linked'
$UATResourceGroupName = 'rg-adf-cicd-linked-uat'
$PRODResourceGroupName = 'rg-adf-cicd-linked-prod'
$DataFactoryName = 'adf-linked-templates-njl'
$DataFactoryPipelineDefinitionFileName = 'DataFactoryPipelines.json' # Uses the file definition to create the Data Factory (ADF) pipelines
$Location = 'eastus'


# # Create the DEV, UAT, PROD resource group names
az group create --name $DEVResourceGroupName --location $Location # DEV
az group create --name $UATResourceGroupName --location $Location # UAT
az group create --name $PRODResourceGroupName --location $Location # PROD


# # Create a Data Factory
az datafactory create --factory-name $DataFactoryName --resource-group $DEVResourceGroupName --location $Location


# # Creates 1000 new Data Factory pipelines (multiple Wait Activities. See DataFactoryPipeline.json file). 
# To deploy fewer or more pipelines, change the -le 1000 below to a different number. Ex: -le 10 will deploy only 10 pipelines.
# Loops from 1 to 1000 creating a pipeline named PL_WAIT_Number. Ex: PL_WAIT_1, PL_WAIT_2... PL_WAIT_200 
for ($i = 1; $i -le 1000; $i++) {
    $PipelineName = "PL_WAIT_" + $i.ToString() # Ex: PL_WAIT_1
    
    # Creates a new Data Factory Pipeline using the Wait Activity Data Factory JSON file: 'DataFactoryPipeline.json'
    az datafactory pipeline create --factory-name $DataFactoryName --pipeline $DataFactoryPipelineDefinitionFileName --name $PipelineName --resource-group $DEVResourceGroupName
}


# To cleanup and delete everything above
# az group delete --name $DEVResourceGroupName
# az group delete --name $UATResourceGroupName
# az group delete --name $PRODResourceGroupName