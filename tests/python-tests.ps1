param (
    [semver] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [string] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform
)

Import-Module (Join-Path $PSScriptRoot "../helpers/pester-extensions.psm1")
Import-Module (Join-Path $PSScriptRoot "../helpers/common-helpers.psm1")
Import-Module (Join-Path $PSScriptRoot "../builders/python-version.psm1")

function Analyze-MissingModules([string] $buildOutputLocation) {
    $searchStringStart = "Failed to build these modules:"
    $searchStringEnd = "running build_scripts"
    $pattern = "$searchStringStart(.*?)$searchStringEnd"

    $buildContent = Get-Content -Path $buildOutputLocation
    $splitBuiltOutput = $buildContent -split "\n";

    ### Search for missing modules that are displayed between the search strings
    $regexMatch = [regex]::match($SplitBuiltOutput, $Pattern)
    if ($regexMatch.Success)
    {
        $module = $regexMatch.Groups[1].Value.Trim()
        Write-Host "Failed missing modules:"
        Write-Host $module
        if ( ($module -eq "_tkinter") -and ( [semver]"$($Version.Major).$($Version.Minor)" -ge [semver]"3.10" -and $Version.PreReleaseLabel ) ) {
          Write-Host "$module $Version ignored"
        } else {
          return 1
        }
    }

    return 0
}

Describe "Tests" {


        It "Check if all required python modules are installed"  {
            "python3 ./sources/python-modules.py" | Should -ReturnZeroExitCode
        }

        It "Check if python configuration is correct" {
            $nativeVersion = Convert-Version -version $Version
            "python ./sources/python-config-test.py $Version $nativeVersion" | Should -ReturnZeroExitCode
        }

    }
