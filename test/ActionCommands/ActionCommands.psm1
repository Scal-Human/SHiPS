using namespace Microsoft.PowerShell.SHiPS

Class GetChildItemParameters {
    [Parameter()]
    [String] $Scope = '*'
}

Class InvokeItemParameters {
    [Parameter()]
    [String] $InvokeData
}

Class NewItemParameters {
    [Parameter()]
    [String] $NewData
}

Class RemoveItemParameters {
    [Parameter()]
    [String] $RemoveData
}


Class RenameItemParameters {
    [Parameter()]
    [String] $RenameData
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

    #Region Invoke-Item
    [Object[]] InvokeItem([String] $Path) {
        Write-Verbose ('{0} {1} {2} {3} {4}' -f $This.GetType().Name, $This.PSPath, 'InvokeItem', $Path, ($This.ProviderContext | ConvertTo-Json -Compress))
        $invocation = [File]::New('Invoked', 'Content')
        $invocation.Data = $This.ProviderContext.DynamicParameters.InvokeData
        $items = @(
            $invocation
        )
        Return $items
    }

    [Object] InvokeItemDynamicParameters() {
        Write-Verbose ('{0} {1} {2}' -f $This.GetType().Name, $This.PSPath, 'InvokeItemDynamicParameters')
        Return ([InvokeItemParameters]::New())
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
        $This.ChildItems = $This.ChildItems | Where-Object Name -Ne (Split-Path -Leaf $Path)
    }

    [Object] RemoveItemDynamicParameters() {
        Write-Verbose ('{0} {1} {2}' -f $This.GetType().Name, $This.Name, 'RemoveItemDynamicParameters')
        Return ([RemoveItemParameters]::New())
    }
    #EndRegion

    #Region Rename-Item
    [Void] RenameItem([String] $Path, [String] $NewName) {
        Write-Verbose ('{0} {1} {2} {3} {4}' -f $This.GetType().Name, $This.Name, 'RenameItem', $NewName, ($This.ProviderContext | ConvertTo-Json -Compress))
        $NewName = Split-Path -Leaf $NewName
        $existing = $This.ChildItems | Where-Object Name -Eq $NewName
        If ($Null -Ne $existing) {
            Throw ('Rename target already exists "{0}"' -f $NewName)
        }
        $item = $This.ChildItems | Where-Object Name -Eq (Split-Path -Leaf $Path)
        If ($Null -Eq $item) {
            Throw ('Item not found "{0}"' -f $Path)
        }
        $item.Name = $NewName
    }

    [Object] RenameItemDynamicParameters() {
        Write-Verbose ('{0} {1} {2}' -f $This.GetType().Name, $This.Name, 'RenameItemDynamicParameters')
        Return ([RenameItemParameters]::New())
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

    #Region Invoke-Item
    [Object[]] InvokeItem([String] $Path) {
        Write-Verbose ('{0} {1} {2} {3} {4}' -f $This.GetType().Name, $This.PSPath, 'InvokeItem', $Path, ($This.ProviderContext | ConvertTo-Json -Compress))
        $invocation = [File]::New('Invoked', 'Content')
        $invocation.Data = $This.ProviderContext.DynamicParameters.InvokeData
        $items = @(
            $invocation
        )
        Return $items
    }

    [Object] InvokeItemDynamicParameters() {
        Write-Verbose ('{0} {1} {2}' -f $This.GetType().Name, $This.PSPath, 'InvokeItemDynamicParameters')
        Return ([InvokeItemParameters]::New())
    }
    #EndRegion

}
