# Helpful Links:
# https://dev.to/adbertram/running-powershell-scripts-in-azure-devops-pipelines-2-of-2-3j0e

[CmdletBinding()]
param(
  $RootFolderPathLinkedARMTemplates,
  $ResourceGroupName
)



$Files = Get-ChildItem -Path $RootFolderPathLinkedARMTemplates -Exclude *master*

    foreach ($FileName in $Files.Name) {
    
      $TemplateSpecName = $FileName.split('.')[0]
    
      az ts create --name $TemplateSpecName --version "1.0.0.0" --resource-group $ResourceGroupName --location 'eastus' --template-file $RootFolderPathLinkedARMTemplates/$FileName --output none
    }

    $ArmTemplateMasterFile = GET-CONTENT $RootFolderPathLinkedARMTemplates/ArmTemplate_master.json -Raw | ConvertFrom-Json

    ($ArmTemplateMasterFile.parameters).PSObject.Properties.Remove('containerUri')
    ($ArmTemplateMasterFile.parameters).PSObject.Properties.Remove('containerSasToken')

    
    foreach ($item in $ArmTemplateMasterFile.resources) {

    $ResourceName = $item.Name -Match 'ArmTemplate_.*'
    $TemplateSpecExtractedName = $matches[0] # $matches is an automatic variable in PowerShell. https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4#matches

    $TemplateSpecResourceID = $(az ts show --name $TemplateSpecExtractedName --resource-group $ResourceGroupName --version "1.0.0.0" --query "id")

    # ($item.properties.templateLink.uri.Split(',')[1]).Trim().replace("'", "").replace('/', '')

    $item.properties.templateLink | Add-Member -Name "id" -value $TemplateSpecResourceID.replace("`"","") -MemberType NoteProperty # $TemplateSpecResourceID.replace("`"","") removes the initial and ending double quotes from the string
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
                [System.Globalization.NumberStyles]::HexNumber))).ToString() } )} |  Set-Content 'NewARMTemplateV2_master.json'