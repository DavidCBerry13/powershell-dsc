[CmdletBinding()]
param(
  [String[]]
  $ComputerName="localhost", 

  [SecureString]
  $WebUserPassword
)


if ($WebUserPassword ) {
    $WebUserCredential = New-Object System.Management.Automation.PSCredential ("WebUser", $WebUserPassword)
}
else {
    # No Password was passed in.  Prompt the user for a password
    $WebUserCredential = Get-Credential -UserName "WebUser" -Message 'Enter Password for WebUser'        
}

# We'll output the MOF file(s) to a directory named 'output' under the directory where this script and the configuration reside
$ScriptPath = Split-Path -parent $PSCommandPath

$OutputPath = Join-Path -Path $ScriptPath -ChildPath "output"
if ( -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType "directory" | Out-Null
}

# This config uses a credential.  But by default, PowerShell will give a warning and error because it does not want to store a plain text credential in the MOF file
# This config when passed to the configuration will allow PowerShell to write the credential, though this is not recommended except for demo/learning purposes
# Further, the NodeName must be the name of the node.  Using NodeName = "*" does not seem to work (PowerShell still generates the error/warning)
# For this reason, we need to look through and create a hashtable for each node inside the AllNodes array
# See https://learn.microsoft.com/en-us/powershell/dsc/configurations/configdatacredentials?view=dsc-1.1
$configData = @{
    AllNodes = @()
}

foreach ($name in $ComputerName) {
    $configData.AllNodes += @{
        NodeName = "$name"
        PSDscAllowDomainUser = $true
        PSDscAllowPlainTextPassword = $true
    }
}


# This imports the configuration
. $ScriptPath\ConfigUsingCredentialsExampleConfiguration.ps1

# This executes the DSC config and outputs the MOF files
ConfigUsingCredentialsExampleConfiguration -OutputPath $OutputPath -ComputerName $ComputerName -WebUserPasswordCredential $WebUserCredential -ConfigurationData $configData