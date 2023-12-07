[CmdletBinding()]
param(
  [String[]]
  $ComputerName="localhost", 

  [String]
  $WebUserPassword
)


if ($WebUserPassword ) {
    $SecurePassword = ConvertTo-SecureString -String $WebUserPassword -Force -AsPlainText
    $WebUserCredential = New-Object System.Management.Automation.PSCredential ("WebUser", $SecurePassword)
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

$CertificatePath = Join-Path -Path $ScriptPath -ChildPath "certificates"
$CertificateFile = Join-Path -Path $CertificatePath -ChildPath "DscPublicKey.cer"
$ThumbprintFile = Join-Path -Path $CertificatePath -ChildPath "thumbprint.txt"

if ( -not (Test-Path -Path $CertificateFile)) {
    Write-Host "Unable to find public key certificate file at $CertificateFile"
    Write-Host "Run the Create-Certificate.ps1 script and try again"
    exit
}

if ( -not (Test-Path -Path $ThumbprintFile)) {
    Write-Host "Unable to find the file containing the certificate thumbprint.  Did you accidently delete this file?"
    exit
}

$Thumbprint = Get-Content -Path $ThumbprintFile -Raw
$Thumbprint

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
        NodeName = $name

        # The path to the .cer file containing the public key of the Encryption Certificate
        # This is used to encrypt the credentials for the node
        CertificateFile = $CertificateFile

        # The thumbprint of the Encryption Certificate
        # This will tell the target node what cert to use to decrypt the credentials
        Thumbprint      = $Thumbprint
    }
}


# This imports the configuration
. $ScriptPath\CredentialsUsingCertificateExampleConfiguration.ps1

# This executes the DSC config and outputs the MOF files
CredentialsUsingCertificateExampleConfiguration -OutputPath $OutputPath -ComputerName $ComputerName -WebUserPasswordCredential $WebUserCredential -ConfigurationData $configData