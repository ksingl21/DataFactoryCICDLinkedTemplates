# Helpful Links:
# https://dev.to/adbertram/running-powershell-scripts-in-azure-devops-pipelines-2-of-2-3j0e

[CmdletBinding()]
param(
  $RootFolderPathLinkedARMTemplates,
  $ResourceGroupName
)


$Files = Get-ChildItem -Path $RootFolderPathLinkedARMTemplates -Exclude *master* # Excludes the master.json and parameters_master.json files

    foreach ($FileName in $Files.Name) {
      
      # Removes .json from the file name. Ex: ArmTemplate_0.json becomes ArmTemplate_0
      $TemplateSpecName = $FileName.split('.')[0]
      
      # Create a new Template Spec for each ARM Template. No need to update the ARM Template at all
      Write-Host "Attempting to create a new template spec for linked ARM template $TemplateSpecName.json"
      az ts create --name $TemplateSpecName --version "1.0.0.0" --resource-group $ResourceGroupName --location 'eastus' --template-file $RootFolderPathLinkedARMTemplates/$FileName --output none
      
      Write-Host `n
      
      Write-Host "Successfully created a new template space for linked ARM template $TemplateSpecName.json"
    }

    Write-Host "Successfully created all necessary Template Specs in Resource Group $ResourceGroupName"

    Write-Host "Attempting to read the ArmTemplate_master.json file"
    $ArmTemplateMasterFile = GET-CONTENT $RootFolderPathLinkedARMTemplates/ArmTemplate_master.json -Raw | ConvertFrom-Json

    # Remove the containerUri and containerSasToken parameters
    ($ArmTemplateMasterFile.parameters).PSObject.Properties.Remove('containerUri')
    ($ArmTemplateMasterFile.parameters).PSObject.Properties.Remove('containerSasToken')

    
    foreach ($item in $ArmTemplateMasterFile.resources) {

    $ResourceName = $item.Name -Match 'ArmTemplate_.*' # Extracts the Arm Template name out of the resource name property. Ex: my-datafactory-name_ArmTemplate_0 returns ArmTemplate_0
    $TemplateSpecExtractedName = $matches[0] # $matches is an automatic variable in PowerShell. https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4#matches

    $TemplateSpecResourceID = $(az ts show --name $TemplateSpecExtractedName --resource-group $ResourceGroupName --version "1.0.0.0" --query "id")

    # ($item.properties.templateLink.uri.Split(',')[1]).Trim().replace("'", "").replace('/', '')

    $item.properties.templateLink | Add-Member -Name "id" -value $TemplateSpecResourceID.replace("`"","") -MemberType NoteProperty # removes the initial and ending double quotes from the string
    ($item.properties.templateLink).PSObject.Properties.Remove('uri')
    ($item.properties.templateLink).PSObject.Properties.Remove('contentVersion')

    $item.apiVersion = '2019-11-01'

    # $item.apiVersion
    # Write-Host $item.properties.templateLink
    # Write-Host $item.properties
    }

    Write-Host "Attempting to output the new Master.json file"

    $ArmTemplateMasterFile | ConvertTo-Json -Depth 15 | %{
    [Regex]::Replace($_, 
        "\\u(?<Value>[a-zA-Z0-9]{4})", {
            param($m) ([char]([int]::Parse($m.Groups['Value'].Value,
                [System.Globalization.NumberStyles]::HexNumber))).ToString() } )} |  Set-Content 'NewARMTemplateV2_master.json' # -Path '$RootFolderPathLinkedARMTemplates'