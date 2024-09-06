

<#
This script does the following things:

Step 1:
- Fetch ADF linkedTemplate files generated during run of adf-build step.
- For each ADF linked template sequence present create a corrosponding template spec in a resource group of your choice.


Step 2:
- Grabs the master file(ArmTemplate_master.json) within the linkedtemplate folder when artifact is generated and does the following:
    - Removes the containerUri and containerSasToken parameters, these are not required when using template specs.
    - For each resource in the ArmTemplate_master.json file :
        - Retrieves the Template Spec Resource ID for that file (ArmTemplate_0 for example)
        - Adds a new id property and adds the Template Spec Resource ID as the value
        - Removes the uri and contentVersion properties
    - Updates the apiVersion property to one that can use the Template Spec id property (2019-11-01 for example) 
    - Ensures the special characters in JSON are escaped properly when generating the updated file (see https://stackoverflow.com/questions/47779157/convertto-json-and-convertfrom-json-with-special-characters)
    - Outputs the new file (doesn't overwrite the existing file) to the root of the repository: Ex: "$(Build.Repository.LocalPath)/NewARMTemplateV2_master.json"


#>


# Defining parameters for the script. The values are passed in from the cicd-pipeline.yml pipeline (Create Template Specs for ADF Linked ARM Templates) task
# All of the parameter values come from the variables files (variables/dev-variables.yml, etc.)
[CmdletBinding()]
param(
  $FolderPathADFLinkedARMTemplates,
  $DeployTemplateSpecsResourceGroupName,
  $DeployTemplateSpecsResourceGroupLocation,
  $TemplateSpecsVersionNumber,
  $TemplateSpecMasterName,
  $OutputFolderPathNewADFMasterARMTemplate
)


# Grabs the ADF linked template files
$LinkedARMTemplateFiles = Get-ChildItem -Path $FolderPathADFLinkedARMTemplates -Exclude *master* # Excludes the ArmTemplate_master.json and ArmTemplateParameters_master.json files

    Write-Host "Attempting to create the Template Specs for the Linked ARM Templates. Template Spec resources will be deployed in Resource Group $DeployTemplateSpecsResourceGroupName. This may take a few of minutes."
    Write-Host `n

    foreach ($FileName in $LinkedARMTemplateFiles.Name) {
      
      # Removes .json from the file name. Ex: ArmTemplate_0.json becomes ArmTemplate_0
      $TemplateSpecName = $FileName.split('.')[0]
      
      # Create a new Template Spec for each ARM Template. Doesn't update the ARM Template at all
      Write-Host "Attempting to create a new Template Spec for linked ARM template $TemplateSpecName.json"
      az ts create --name $TemplateSpecName --version $TemplateSpecsVersionNumber --resource-group $DeployTemplateSpecsResourceGroupName --location $DeployTemplateSpecsResourceGroupLocation `
        --template-file $FolderPathADFLinkedARMTemplates/$FileName --yes --output none # --yes means don't prompt for confirmation and overwrite the existing Template Spec if it exists
      
      Write-Host "Successfully created a new Template Spec called $TemplateSpecName for Linked ARM Template $TemplateSpecName.json"
      Write-Host `n
    }

    Write-Host "Successfully created all necessary Template Specs in Resource Group $DeployTemplateSpecsResourceGroupName"
    Write-Host `n


    # Reading the ArmTemplate_master.json file
    Write-Host "Attempting to read the ArmTemplate_master.json file"
    $MasterARMTemplateFile = Get-Content $FolderPathADFLinkedARMTemplates/ArmTemplate_master.json -Raw | ConvertFrom-Json
    Write-Host "Successfully read the ArmTemplate_master.json file"

    # Remove the containerUri and containerSasToken parameters
    ($MasterARMTemplateFile.parameters).PSObject.Properties.Remove('containerUri')
    ($MasterARMTemplateFile.parameters).PSObject.Properties.Remove('containerSasToken')

    
    foreach ($Resource in $MasterARMTemplateFile.resources) {

    $ResourceName = $Resource.Name -Match 'ArmTemplate_.*' # Extracts the ARM Template name out of the resource name property. Ex: my-datafactory-name_ArmTemplate_0 returns ArmTemplate_0
    $TemplateSpecExtractedName = $matches[0] 


    $TemplateSpecResourceID = $(az ts show --name $TemplateSpecExtractedName --resource-group $DeployTemplateSpecsResourceGroupName --version $TemplateSpecsVersionNumber --query "id")

    $Resource.properties.templateLink | Add-Member -Name "id" -value $TemplateSpecResourceID.replace("`"","") -MemberType NoteProperty # removes the initial and ending double quotes from the string
    
    ($Resource.properties.templateLink).PSObject.Properties.Remove('uri')
    ($Resource.properties.templateLink).PSObject.Properties.Remove('contentVersion')

    # Updates the API version to one that can use the Template Spec ID
    $Resource.apiVersion = '2019-11-01'
    }

    Write-Host "Attempting to output the new Master.json file"

    # Ensures the JSON special characters are escaped and come through correctly. For example, not returning a \u0027 string value.
  
    $MasterARMTemplateFile | ConvertTo-Json -Depth 15 | ForEach-Object{
    [Regex]::Replace($_, 
        "\\u(?<Value>[a-zA-Z0-9]{4})", {
            param($m) ([char]([int]::Parse($m.Groups['Value'].Value,
                [System.Globalization.NumberStyles]::HexNumber))).ToString() } )} |  Set-Content "$TemplateSpecMasterName.json"

    Write-Host "Successfully created the $TemplateSpecMasterName.json file"
    
    Write-Host "Attempting to create the Template Spec for the $TemplateSpecMasterName.json file"

    az ts create --name $TemplateSpecMasterName --version $TemplateSpecsVersionNumber --resource-group $DeployTemplateSpecsResourceGroupName --location $DeployTemplateSpecsResourceGroupLocation `
      --template-file "$OutputFolderPathNewADFMasterARMTemplate/$TemplateSpecMasterName.json" --output none
    
    Write-Host "Successfully created the master Template Spec. Name: $TemplateSpecMasterName in Resource Group $DeployTemplateSpecsResourceGroupName"

    


