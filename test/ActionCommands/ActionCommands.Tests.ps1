# Explicit use of Pester to avoid its loading to appear when Verbose is requested
#Requires -Module Pester
<#
    Note:
        I was unable to run the tests from test\automation\navigation.tests.ps1 ($script:homePath issue).
        So how do I integrate them when I cannot test them ?
#>
[CmdletBinding()] # So we have Verbose, Debug & co
Param ()

Set-Alias -Name 'Given' -Value 'Context' # -Option AllScope # Pester conflicts with PSScriptAnalyzer because non-standard naming

Describe 'ActionCommands' {

    BeforeAll {
        Import-Module -Force (Join-Path $PSScriptRoot '..\..\src\out\SHiPS\SHiPS.psd1') -Verbose:$False
        Import-Module -Force (Join-Path $PSScriptRoot 'ActionCommands.psm1') -Verbose:$False
        New-PSDrive -Name 'ActionCommands' -PSProvider SHiPS -Root 'ActionCommands#Root'
    }
    AfterAll {
        Remove-PSDrive -Name 'ActionCommands'
        Remove-Module -Force 'SHiPS' -Verbose:$False
    }

    Describe 'New-Item' {
        Given 'SHiPSDirectory' {
            BeforeAll {
                $Null = New-Item 'ActionCommands:\Directory' -ItemType 'Directory'
            }
            It 'Should fail' {
                $parameters = @{
                    Path = 'ActionCommands:\Directory\NewFile1'
                    ItemType = 'Dummy'
                }
                {
                     New-Item  @parameters -Verbose:($VerbosePreference -Eq 'Continue') -ErrorAction Stop
                } | Should -Throw
            }
        }
        Given 'Folder class' {
            It 'Creates aa file' {
                $parameters = @{
                    Path = 'ActionCommands:\NewFile1'
                    ItemType = 'Dummy'
                }
                $result = New-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                $result | Format-List | Out-String | Write-Information
                $result | Should -Not -Be $Null
                $result.Name | Should -Be (Split-Path -Leaf $parameters.Path)
                $result.ItemType | Should -Be $parameters.ItemType
            }
            It 'Accepts specific parameters' {
                $parameters = @{
                    Path = 'ActionCommands:\NewFile2'
                    ItemType = 'Dummy'
                    NewData = 'NewData'
                }
                $result = New-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                $result | Format-List | Out-String | Write-Information
                $result | Should -Not -Be $Null
                $result.Name | Should -Be (Split-Path -Leaf $parameters.Path)
                $result.ItemType | Should -Be $parameters.ItemType
                $result.Data | Should -Be $parameters.NewData
            }
            It 'Creates a folder' {
                $parameters = @{
                    Path = 'ActionCommands:\NewFolder1'
                    ItemType = 'Folder'
                    NewData = 'NewData'
                }
                $result = New-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                $result | Format-List | Out-String | Write-Information
                $result | Should -Not -Be $Null
                $result.Name | Should -Be (Split-Path -Leaf $parameters.Path)
                $result.ItemType | Should -Be $parameters.ItemType
                $result.Data | Should -Be $parameters.NewData
            }
            It 'Rejects duplicate' {
                $parameters = @{
                    Path = 'ActionCommands:\NewFile3'
                    ItemType = 'Dummy'
                }
                $Null = New-Item @parameters
                {
                     New-Item  @parameters -Verbose:($VerbosePreference -Eq 'Continue') -ErrorAction Stop
                } | Should -Throw
            }
        }
    }

    Describe 'Remove-Item' {
        Given 'Existing structure' {
            BeforeAll {
                $Null = New-Item 'ActionCommands:\FolderToDelete1' -ItemType 'Folder'
                $Null = New-Item 'ActionCommands:\FolderToDelete2' -ItemType 'Folder'
                $Null = New-Item 'ActionCommands:\FolderToDelete2\File1'
                $Null = New-Item 'ActionCommands:\FolderToDelete2\File2'
                $Null = New-Item 'ActionCommands:\FileToDelete1'
                $Null = New-Item 'ActionCommands:\FileToDelete2'
            }
            It 'Removes empty folder' {
                $parameters = @{
                    Path = 'ActionCommands:\FolderToDelete1'
                }
                Remove-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                { Get-Item $parameters.Path -Force -ErrorAction Stop } | Should -Throw
            }
            It 'Removes non-empty folder (recurse)' {
                $parameters = @{
                    Path = 'ActionCommands:\FolderToDelete2'
                    Recurse = $True
                    Confirm = $False
                }
                Remove-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                { Get-Item $parameters.Path -Force -ErrorAction Stop } | Should -Throw
            }
            It 'Removes file' {
                $parameters = @{
                    Path = 'ActionCommands:\FileToDelete1'
                }
                Remove-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                { Get-Item $parameters.Path -Force -ErrorAction Stop } | Should -Throw
            }
            It 'Accepts specific parameters' {
                $parameters = @{
                    Path = 'ActionCommands:\FileToDelete2'
                    RemoveData = 'Recycle'
                }
                Remove-Item @parameters -Verbose:($VerbosePreference -Eq 'Continue')
                { Get-Item $parameters.Path -Force -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
