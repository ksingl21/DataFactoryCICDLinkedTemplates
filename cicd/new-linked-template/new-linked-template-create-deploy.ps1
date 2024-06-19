# Helpful Links:
# https://dev.to/adbertram/running-powershell-scripts-in-azure-devops-pipelines-2-of-2-3j0e
# https://stackoverflow.com/questions/47779157/convertto-json-and-convertfrom-json-with-special-characters
# https://learn.microsoft.com/en-us/cli/azure/delete-azure-resources-at-scale#delete-all-azure-resources-of-a-type


# Defining parameters for the script
[CmdletBinding()]
param(
  $FolderPathADFLinkedARMTemplates,
  $DeployTemplateSpecsResourceGroupName
)


$LinkedARMTemplateFiles = Get-ChildItem -Path $FolderPathADFLinkedARMTemplates -Exclude *master* # Excludes the master.json and parameters_master.json files

    Write-Host "Attempting to create the template specs for the linked ARM templates. Template Spec resources will be deployed in Resource Group $DeployTemplateSpecsResourceGroupName. This may take a couple of mins."
    Write-Host `n

    foreach ($FileName in $LinkedARMTemplateFiles.Name) {
      
      # Removes .json from the file name. Ex: ArmTemplate_0.json becomes ArmTemplate_0
      $TemplateSpecName = $FileName.split('.')[0]
      
      # Create a new Template Spec for each ARM Template. Doesn't update the ARM Template at all
      Write-Host "Attempting to create a new Template Spec for linked ARM template $TemplateSpecName.json"
      az ts create --name $TemplateSpecName --version "1.0.0.0" --resource-group $DeployTemplateSpecsResourceGroupName --location 'eastus' --template-file $FolderPathADFLinkedARMTemplates/$FileName --yes --output none
      
      Write-Host "Successfully created a new Template Spec called $TemplateSpecName for linked ARM template $TemplateSpecName.json"
      Write-Host `n
    }

    Write-Host "Successfully created all necessary Template Specs in Resource Group $DeployTemplateSpecsResourceGroupName"

    Write-Host "Attempting to read the ArmTemplate_master.json file"
    $ArmTemplateMasterFile = GET-CONTENT $FolderPathADFLinkedARMTemplates/ArmTemplate_master.json -Raw | ConvertFrom-Json

    # Remove the containerUri and containerSasToken parameters
    ($ArmTemplateMasterFile.parameters).PSObject.Properties.Remove('containerUri')
    ($ArmTemplateMasterFile.parameters).PSObject.Properties.Remove('containerSasToken')

    
    foreach ($item in $ArmTemplateMasterFile.resources) {

    $ResourceName = $item.Name -Match 'ArmTemplate_.*' # Extracts the Arm Template name out of the resource name property. Ex: my-datafactory-name_ArmTemplate_0 returns ArmTemplate_0
    $TemplateSpecExtractedName = $matches[0] # $matches is an automatic variable in PowerShell. https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4#matches

    $TemplateSpecResourceID = $(az ts show --name $TemplateSpecExtractedName --resource-group $DeployTemplateSpecsResourceGroupName --version "1.0.0.0" --query "id")

    $item.properties.templateLink | Add-Member -Name "id" -value $TemplateSpecResourceID.replace("`"","") -MemberType NoteProperty # removes the initial and ending double quotes from the string
    ($item.properties.templateLink).PSObject.Properties.Remove('uri')
    ($item.properties.templateLink).PSObject.Properties.Remove('contentVersion')

    $item.apiVersion = '2019-11-01'

    }


    Write-Host "Attempting to output the new Master.json file"

    # Ensures the JSON special characters are escaped and come through correctly. For example not returning a \u0027 string value.
    # See https://stackoverflow.com/questions/47779157/convertto-json-and-convertfrom-json-with-special-characters for more details.
    $ArmTemplateMasterFile | ConvertTo-Json -Depth 15 | %{
    [Regex]::Replace($_, 
        "\\u(?<Value>[a-zA-Z0-9]{4})", {
            param($m) ([char]([int]::Parse($m.Groups['Value'].Value,
                [System.Globalization.NumberStyles]::HexNumber))).ToString() } )} |  Set-Content 'NewARMTemplateV2_master.json'

    Write-Host "Successfully created the NewARMTemplateV2_master.json file"
