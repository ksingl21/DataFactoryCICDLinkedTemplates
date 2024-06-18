# Creates the following new resources:
    # DEV, UAT and PROD resource groups
    # Creates a new Data Factory in the DEV resource group 
    # Creates 200 new Data Factory pipelines (35 Wait Activities in each pipeline) to create an overall ARM template over 4MB
    # Links the Data Factory to a GitHub repo.


    # https://learn.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-generate-sas
    # https://andrewmatveychuk.com/how-to-deploy-linked-arm-templates-from-private-azure-devops-repositories/
    # https://github.com/starkfell/100DaysOfIaC/blob/master/articles/day.42.deploy.nested.arm.templates.using.storage.accounts.in.yaml.pipeline.md?ref=andrewmatveychuk.com#1-preparing-the-arm-templates
    # https://www.nathannellans.com/post/ci-cd-with-azure-data-factory-part-2
    # https://github.com/nnellans/azure-data-factory/tree/main


    # https://github.com/JFolberth/TheYAMLPipelineOne
    # https://blog.johnfolberth.com/deploying-linked-arm-templates-via-yaml-pipelines/


# Resource Names and Config
$DEVResourceGroupName = 'rg-adf-cicd-linked'
$UATResourceGroupName = 'rg-adf-cicd-linked-uat'
$PRODResourceGroupName = 'rg-adf-cicd-linked-prod'
$DataFactoryName = 'adf-linked-templates-njl'
$DataFactoryPipelineDefinitionFileName = 'DataFactoryPipeline.json'
$Location = 'eastus'

# GitHub Repo Config. Used to connect the Data Factory to the GitHub repo
$GitHubHostNameURL = 'https://github.com/DataEngineeringWithNick/DataFactoryCICDLinkedTemplates'
$GitHubAccountName = 'DataEngineeringWithNick'
$GitHubRepositoryName = 'DataFactoryCICDLinkedTemplates'
$GitHubRepoCollaborationBranchName = 'main'
$GitHubRepoRootFolderName = '/'


# # Create the DEV, UAT, PROD resource group names
# az group create --name $DEVResourceGroupName --location $Location # DEV
# az group create --name $UATResourceGroupName --location $Location # UAT
# az group create --name $PRODResourceGroupName --location $Location # PROD


# # Create a Data Factory
az datafactory create --factory-name $DataFactoryName --resource-group $DEVResourceGroupName --location $Location


# # Creates 200 new Data Factory pipelines (35 Wait Activities in each pipeline). 
# To deploy fewer or more pipelines, change the -le 200 to a different number. Ex: -le 10 will deploy 10 pipelines.
# Loops from 1 to 200 creating a pipeline named PL_WAIT_Number. Ex: PL_WAIT_1, PL_WAIT_2... PL_WAIT_200 
for ($i = 1; $i -le 10; $i++) {
    $PipelineName = "PL_WAIT_" + $i.ToString() # Ex: PL_WAIT_1
    
    # Creates a new Data Factory Pipeline using the 35 Wait Activity Data Factory JSON file: 'DataFactoryPipeline.json'
    az datafactory pipeline create --factory-name $DataFactoryName --pipeline $DataFactoryPipelineDefinitionFileName --name $PipelineName --resource-group $DEVResourceGroupName
}


# Configure Data Factory to GitHub repo

# Get the resource ID for the Data Factory. Ex: /subscriptions/xxxxxx/resourceGroups/xxxxx/providers/Microsoft.DataFactory/factories/datafactoryname
$DataFactoryResourceID = $(az ad sp list --filter "displayname eq '$DataFactoryName'" --query "[].alternativeNames[1]" --output tsv)


# # Configures the Data Factory to the GitHub repo
az datafactory configure-factory-repo --factory-git-hub-configuration host-name=$GitHubHostNameURL  account-name=$GitHubAccountName repository-name=$GitHubRepositoryName `
    collaboration-branch=$GitHubRepoCollaborationBranchName root-folder=$GitHubRepoRootFolderName --location $Location `
    --factory-resource-id $DataFactoryResourceID

# Manual step:
    # Go into the Data Factory, manage tab, Git Configuration then import resources to main branch.


# To cleanup and delete everything above
# az group delete --name $DEVResourceGroupName
# az group delete --name $UATResourceGroupName
# az group delete --name $PRODResourceGroupName