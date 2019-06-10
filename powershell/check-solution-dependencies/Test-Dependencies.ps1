param(
    [Parameter(
        Mandatory=$true,
        ParameterSetName="CommandLine")]
    [String]
    $DynamicsConnectionString,

    [Parameter(
        Mandatory=$true,
        ParameterSetName="CommandLine")]
    $InputFile,

    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="Interactive")]
    [Switch]
    $InteractiveMode,

    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="Interactive")]
    [Hashtable]
    $MissingDependencies
)

. "$PSScriptRoot\ComponentType.ps1"

If ($InteractiveMode -eq $true) {
    $connection = Get-CrmConnection -InteractiveMode
} Else {
    $connection = Get-CrmConnection -ConnectionString $DynamicsConnectionString
    $MissingDependencies = (Import-Clixml $InputFile)
}

foreach($componentType in $MissingDependencies.Keys) {
    switch($componentType) {
        ([ComponentType]::Entity) {
            foreach($entityLogicalName in $MissingDependencies[$componentType]) {
                Write-Output "Checking entity ""$entityLogicalName""..."
                $request = Invoke-CrmAction `
                    -conn $connection `
                    -Name RetrieveEntity `
                    -Parameters @{
                        EntityFilters = [Microsoft.Xrm.Sdk.Metadata.EntityFilters]::Entity
                        LogicalName = $entityLogicalName
                        MetadataId = [Guid]::Empty
                        RetrieveAsIfPublished = $false
                    }
                Write-Output "Found."
            }
        }
        ([ComponentType]::Attribute) {
            foreach($attributeJson in $MissingDependencies[$componentType]) {
                $attributeNameObject = ConvertFrom-Json $attributeJson
                $attributeName = $attributeNameObject.AttributeName
                $entityName = $attributeNameObject.EntityName
                Write-Output "Checking attribute ""$attributeName"" on entity ""$entityName""..."
                $request = Invoke-CrmAction `
                    -conn $connection `
                    -Name RetrieveAttribute `
                    -Parameters @{
                        EntityLogicalName = $entityName
                        LogicalName = $attributeName
                        MetadataId = [Guid]::Empty
                        RetrieveAsIfPublished = $false
                    }
                If ($request -ne $null) {
                    Write-Output "Found."
                }
            }
        }
        default {
            Write-Error `
                -Message "Component type ($componentType) not implemented." `
                -Category NotImplemented
        }
    }
}