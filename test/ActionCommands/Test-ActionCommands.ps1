[CmdletBinding()]
Param (
    [Parameter()] [String] $TestPath    = (Join-Path $PSScriptRoot 'ActionCommands.Tests.ps1'),
    [Parameter()] [String[]] $Tags,
    [Parameter()] [Switch] $PassThru
)

$configuration = @{
    Filter = @{
        Tag = $Tags
    }
    Run = @{
        Path = $TestPath
        PassThru = ($True -Eq $PassThru)
    }
    Output = @{
        Verbosity = 'Detailed'
    }
    TestResult = @{
        Enabled = $True
        OutputPath = $TestPath.Replace('.Tests.ps1', '.Results.xml')
        OutputFormat = "NUnitXml"
    }
}
Invoke-Pester -Configuration $configuration
