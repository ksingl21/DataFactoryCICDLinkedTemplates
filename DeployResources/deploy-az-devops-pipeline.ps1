# Creates a new Azure DevOps Pipeline for the Data Factory Linked Template Code

# Helpful Links:
# https://learn.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops


# Prerequisites:
# Acquire a Personal Access Token in the DevOps project and save in AzureDevopsDEWithNickPAT local env variable:    
    # To acquire an access token, go to AzurePipelineDataFactoryCICD Azure DevOps project, top right under user settings, 
    # personal Access Token, create one then save as environment variable on my comp. 


# Uses the AZURE_DEVOPS_EXT_PAT environment variable option to login to use the az devops commands. See helpful links section.
# Alternative way to set an environment variable: [Environment]::SetEnvironmentVariable('AZURE_DEVOPS_EXT_PAT', $env:AzureDevopsDEWithNickPAT)
$env:AZURE_DEVOPS_EXT_PAT = $env:AzureDevopsDEWithNickPAT


# Resource Names and Config
$AzurePipelineName = 'DataFactoryCICDLinkedTemplates'
$AzurePipelineYamlFilePath = 'DataFactoryCICDLinkedTemplates/cicd/cicd-pipeline.yml'

$AzureDevOpsOrganizationURL = $env:AzureDevopsDEWithNickOrganizationURL # Ex: https://dev.azure.com/MyOrganizationName/
$AzureDevOpsProjectName = $env:AzureDevopsDEWithNickADFCICDProjectName  # Ex: MyProjectName
$AzureDevOpsGitHubServiceConnectionResourceID = $env:AzureDevopsDEWithNickGitHubServiceConnectionResourceID # EX: 14679448-b45e-6774-11bt-6dyca571331b
    # To find the Service Connection resource ID, go to my ADF CICD DevOps project, project settings, 
        # service connections, GitHub ADF Service connection name then at top shows the resource ID.


# Checks if the Azure Pipeline already exists. 
# Returns the name of the pipeline or nothing if it doesn't currently exist. Ex: "MyPipeline1"
$CheckIfPipelineExists = az pipelines list --organization $AzureDevOpsOrganizationURL --project $AzureDevOpsProjectName `
    --query "[?name=='$AzurePipelineName'].{Name:name} | [0].Name"


# If $ChickIfPipelineExists is empty (pipeline doesn't exist), the length would be zero.
if ($CheckIfPipelineExists.Length -eq 0) 
{
    az pipelines create --name $AzurePipelineName --organization $AzureDevOpsOrganizationURL --project $AzureDevOpsProjectName `
        --service-connection $AzureDevOpsGitHubServiceConnectionResourceID --yaml-path $AzurePipelineYamlFilePath --skip-first-run true 
        # --skip-first-run just creates the pipeline and doesn't run the pipeline the first time after creation
}
else 
{
    Write-Host "Pipeline '$AzurePipelineName' already exists. Skipping the creation of the pipeline."
} 


# To delete and clean up everything

# # Get the ID of the pipeline
# $PipelineID = az pipelines list --organization $AzureDevOpsOrganizationURL --project $AzureDevOpsProjectName `
#     --query "[?name=='$AzurePipelineName'] | [0].id"

# az pipelines delete --id $PipelineID --organization $AzureDevOpsOrganizationURL --project $AzureDevOpsProjectName --yes
#     # --yes: don't prompt for confirmation