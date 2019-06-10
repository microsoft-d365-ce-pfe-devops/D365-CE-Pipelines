param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [String]
    $SolutionName,

    [Parameter(
        Mandatory=$true,
        ParameterSetName="CommandLine")]
    [String]
    $DynamicsConnectionString,

    [Parameter(
        Mandatory=$true,
        ParameterSetName="CommandLine")]
    $OutputFile,

    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="Interactive")]
    [Switch]
    $InteractiveMode
)

. "$PSScriptRoot\ComponentType.ps1"

If ($InteractiveMode -eq $true) {
    $connection = Get-CrmConnection -InteractiveMode
} Else {
    $connection = Get-CrmConnection -ConnectionString $DynamicsConnectionString
}

# Retrieve all missing dependencies from the solution
$rawMissingDependencies = Invoke-CrmAction `
    -conn $connection `
    -Name RetrieveMissingDependencies `
    -Parameters @{
        SolutionUniqueName = $SolutionName
    }

# Create some delegate functions for getting attribute values from an entity
$getAttributeValueGuid = [Microsoft.Xrm.Sdk.Entity].GetMethod("GetAttributeValue").MakeGenericMethod([Guid])
$getAttributeValueOptionSet = [Microsoft.Xrm.Sdk.Entity].GetMethod("GetAttributeValue").MakeGenericMethod([Microsoft.Xrm.Sdk.OptionSetValue])

<# Parse the results of the dependencies into a map of guid's
Format:
$missingDependencyIds = @{
    [ComponentType]::Entity = {
        "01234567-890A-BCDE-F012-34567890ABCD",
        "12345678-90AB-CDEF-0123-4567890ABCDE",
        ...
    },
    [ComponentType]::Attribute = {
        "23456789-0ABC-DEF0-1234-567890ABCDEF",
        "34567890-ABCD-EF01-2345-67890ABCDEF0",
        ...
    },
    ...
}
#>
$missingDependencyIds = @{}
foreach ($entity in $rawMissingDependencies.EntityCollection.Entities) {
    $componentType = [ComponentType]($getAttributeValueOptionSet.Invoke($entity, "requiredcomponenttype").Value)
    $objectId = $getAttributeValueGuid.Invoke($entity, "requiredcomponentobjectid")
    if(-Not $missingDependencyIds.ContainsKey($componentType)) {
        $missingDependencyIds.Add($componentType, (New-Object System.Collections.Generic.HashSet[Guid])) | Out-Null
    }
    $missingDependencyIds[$componentType].Add($objectId) | Out-Null
}

<# Iterate through the collection of Guid's and convert them to string's so that they can be checked in a target environment
Format:
$missingDependencies = @{
    [ComponentType]::Entity = {
        "cou_building",
        "cou_department",
        ...
    },
    [ComponentType]::Attribute = {
        @{
            EntityName = "cou_building",
            AttributeName = "cou_abbreviation"
        },
        @{
            EntityName = "cou_department",
            AttributeName = "cou_managerid"
        },
        ...
    },
    ...
}
#>
$missingDependencies = @{}
foreach($componentType in $missingDependencyIds.Keys) {    
    If(-Not $missingDependencies.ContainsKey($componentType)) {
        $missingDependencies.Add($componentType, (New-Object System.Collections.Generic.HashSet[String])) | Out-Null
    }
    
    $objectIds = $missingDependencyIds[$componentType]

    switch($componentType) {
        # Entity's are represented with a string representing the entity's logical name
        ([ComponentType]::Entity) {
            foreach($metadataId in $objectIds) {
                $request = Invoke-CrmAction `
                    -conn $connection `
                    -Name RetrieveEntity `
                    -Parameters @{
                        EntityFilters = [Microsoft.Xrm.Sdk.Metadata.EntityFilters]::Entity
                        MetadataId = $metadataId
                        RetrieveAsIfPublished = $false
                    }
                $missingDependencies[$componentType].Add($request.EntityMetadata.LogicalName) | Out-Null
            }
        }
        <# Attributes are represented as a JSON object of the format:
        { 
            "EntityName": "<EntityLogicalName>",
            "AttributeName": "<AttributeLogicalName>"
        }
        #>
        ([ComponentType]::Attribute) {
            foreach($metadataId in $objectIds) {
                $request = Invoke-CrmAction `
                    -conn $connection `
                    -Name RetrieveAttribute `
                    -Parameters @{
                        MetadataId = $metadataId
                        RetrieveAsIfPublished = $false
                    }
                $attribute = $request.AttributeMetadata
                $missingDependencies[$componentType].Add((ConvertTo-Json @{
                    EntityName = $attribute.EntityLogicalName
                    AttributeName = $attribute.LogicalName
                })) | Out-Null
            }
        }
        default {
            Write-Error `
                -Message "Component type ($componentType) not implemented." `
                -Category NotImplemented
        }
    }
}

If($InteractiveMode -eq $true) {
    Write-Output $missingDependencies
} Else {
    $missingDependencies | Export-Clixml $OutputFile
}