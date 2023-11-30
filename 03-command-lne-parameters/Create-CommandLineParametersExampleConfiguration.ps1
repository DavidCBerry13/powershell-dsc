[CmdletBinding()]
param(
  [String[]]
  $ComputerName="localhost", 

  [Parameter(Mandatory = $true)]
  [String]
  [ValidateSet("Eastern",
    "Central",
    "Mountain",
    "Arizona",
    "Pacific",
    "Alaska",
    "Hawaii")]
  $TimeZone
)

# Hashtable to translate shorter/friendlier names to PowerShell TimeZoneId values (From Get-TimeZone -ListAvailable)
$TimeZones = @{
    Eastern = "Eastern Standard Time"
    Central = "Central Standard Time"
    Mountain = "Mountain Standard Time"
    Arizona = "US Mountain Standard Time"    
    Pacific = "Pacific Standard Time"
    Alaska = "Alaskan Standard Time"
    Hawaii = "Hawaiian Standard Time"
}

$TimeZoneId = $TimeZones[$TimeZone]

Write-Host "Time zone data is $TimeZone  $TimeZoneId"

# We'll output the MOF file(s) to a directory named 'output' under the directory where this script and the configuration reside
$ScriptPath = Split-Path -parent $PSCommandPath

$OutputPath = Join-Path -Path $ScriptPath -ChildPath "output"
if ( -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType "directory" | Out-Null
}

# This imports the configuration
. $ScriptPath\CommandLineParametersExampleConfiguration.ps1

# This executes the DSC config and outputs the MOF files
CommandLineParametersExampleConfiguration -OutputPath $OutputPath -ComputerName $ComputerName -TimeZoneId $TimeZoneId