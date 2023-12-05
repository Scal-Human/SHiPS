using namespace Microsoft.PowerShell.SHiPS

Class GetChildItemParameters {
    [Parameter()]
    [String] $Scope = '*'
}

Class NewItemParameters {
    [Parameter()]
    [String] $NewData
}

Class RemoveItemParameters {
    [Parameter()]
    [String] $RemoveData
}

[SHiPSProvider(UseCache = $True)]
class Folder : SHiPSDirectory
{
    [String] $ItemType
    [String] $Data
    Hidden [Object[]] $ChildItems = @()

    Folder([string]$name): base($name){}
    
    #Region Get-ChildItem
    [Object] GetChildItemDynamicParameters() {
        Return ([GetChildItemParameters]::New())
    }

    [object[]] GetChildItem() {
        $items = @( $This.ChildItems )
        Return $items
    }
    #EndRegion

    #Region New-Item
    [Object] NewItem([String] $Path, [String] $itemTypeName) {
        Write-Verbose ('{0} {1} {2} {3} {4}' -f $This.GetType().Name, $This.PSPath, 'NewItem', $Path, ($This.ProviderContext | ConvertTo-Json -Compress))
        $newItem = $Null
        Switch ($itemTypeName) {
            'Directory' {
                $newItem = [SHiPSDirectory]::New((Split-Path -Leaf $Path))
                Break
            }
            'Folder' {
                $newItem = [Folder]::New((Split-Path -Leaf $Path))
                $newItem.ItemType = $itemTypeName
                $newItem.Data = $This.ProviderContext.DynamicParameters.NewData
                Break
            }
            Default {
                $newItem = [File]::New((Split-Path -Leaf $Path), $itemTypeName)
                $newItem.ItemType = $itemTypeName
                $newItem.Data = $This.ProviderContext.DynamicParameters.NewData
                Break
            }
        }
        If ($Null -Ne  $newItem) {
            $This.ChildItems += $newItem
        }
        Return $newItem
    }

    # Todo: Not Working
    [String[]] NewItemTypeNames() {
        Return @( 'Type1', 'Type2' )
    }

    [Object] NewItemDynamicParameters() {
        Write-Verbose 'NewItemDynamicParameters'
        Return ([NewItemParameters]::New())
    }
    #EndRegion
    #Region Remove-Item
    [Void] RemoveItem([String] $Path) {
        Write-Verbose ('{0} {1} {2} {3} {4}' -f $This.GetType().Name, $This.Name, 'RemoveItem', (Split-Path -Leaf $Path), ($This.ProviderContext | ConvertTo-Json -Compress))
        # $This.ChildItems | Format-Table | Out-String | Write-Warning
        $This.ChildItems = $This.ChildItems | Where-Object Name -Ne (Split-Path -Leaf $Path)
        # $This.ChildItems | Format-Table | Out-String | Write-Warning
    }

    [Object] RemoveItemDynamicParameters() {
        Write-Verbose ('{0} {1} {2}' -f $This.GetType().Name, $This.Name, 'RemoveItemDynamicParameters')
        Return ([RemoveItemParameters]::New())
    }
    #EndRegion
}

[SHiPSProvider(UseCache = $True)]
class Root : Folder
{
    Root([string]$name): base($name){}
}

[SHiPSProvider(UseCache = $True)]
class File : SHiPSLeaf
{
    [String] $ItemType
    [String] $Data
    Hidden [String] $Content

    File([string]$name): base($name){
    }

    File([string]$name, [String] $Content): base($name){
        $This.Content = $Content
    }

}
