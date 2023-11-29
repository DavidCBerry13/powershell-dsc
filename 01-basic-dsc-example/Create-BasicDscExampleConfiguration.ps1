# We'll output the MOF file(s) to a directory named 'output' under the directory where this script and the configuration reside
$ScriptPath = Split-Path -parent $PSCommandPath

$OutputPath = Join-Path -Path $ScriptPath -ChildPath "output"
if ( -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType "directory"
}

# This imports the configuration
. $ScriptPath\BasicDscExampleConfiguration.ps1

# This executes the DSC config and outputs the MOF files
BasicDscExampleConfiguration -OutputPath $OutputPath