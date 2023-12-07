
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]
    $PfxPassword,

    [int]
    $Months = 24
)


# This script needs to be run with administrative permissions, so check up top and tell teh user if they are not.
if (-not ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))) {
    Write-Host -ForegroundColor Red "This script to generate a certificate must be run in an Administrator PowerShell session"
    Write-Host -ForegroundColor Red "Please create a new PowerShell session using 'Run as Administrator' and re-run this script to create the certificate"
    exit
}

# The certificate files will be output to a subdirectory named 'certificates' under where this script resides
$ScriptPath = Split-Path -parent $PSCommandPath

$OutputPath = Join-Path -Path $ScriptPath -ChildPath "certificates"
if ( -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType "directory" | Out-Null
}

# For Certificates, per the page at https://learn.microsoft.com/en-us/powershell/dsc/pull-server/securemof?view=dsc-1.1
#   - The Key Usage field ust contain 'KeyEncipherment' and 'DataEncipherment' but should not contain Digital Signature
#   - The Enhanced Key Usage must contain Document Encryption (1.3.6.1.4.1.311.80.1) but should not contain Client 
#         Authentication (1.3.6.1.5.5.7.3.2) and Server Authentication (1.3.6.1.5.5.7.3.1)
#   - The provider must be 'Microsoft RSA SChannel Cryptographic Provider'
#
# KeyUsage and Provider can be set as arguments to the New-SelfSignedCetificate cmdlet.  Enhanced Key usage is set as 
# part of the Extension to the argument, and you need wrap up the Document Encryption value in an OID collection.  An 
# example of how to do this is found at https://github.com/nanalakshmanan/xDSCUtils/blob/master/xDSCUtils.psm1.  This
# code is based off of that example

# OID for document encryption
$docEncryptionOid = New-Object System.Security.Cryptography.Oid "1.3.6.1.4.1.311.80.1"
$oidCollection = New-Object System.Security.Cryptography.OidCollection
$oidCollection.Add($docEncryptionOid) | Out-Null

# Create enhanced key usage extension that allows document encryption
$extension = New-Object System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension $oidCollection, $true

# Put the parameters for the certificate into a hashtable and generate the certificate
$certificateParams = @{
    DnsName = 'DscEncryptionCert'
    HashAlgorithm = "SHA256"
    KeyUsage = @("KeyEncipherment","DataEncipherment")
    Extension = $extension
    Provider = "Microsoft RSA SChannel Cryptographic Provider"
    NotAfter = (Get-Date).AddMonths($Months)
}
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp @certificateParams

# Export the private key certificate
$SecurePfxPassword = ConvertTo-SecureString -String $PfxPassword -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "$OutputPath\DscPrivateKey.pfx" -Password $SecurePfxPassword -Force

# Export the public key certificate
$cert | Export-Certificate -FilePath "$OutputPath\DscPublicKey.cer" -Force

# Output the thumbprint because we will need to include this in our DSC to use the certificate
$cert.Thumbprint | Out-File -FilePath "$OutputPath\thumbprint.txt"
Write-Host "Certificate Thumbprint is $($cert.Thumbprint)"

# Remove the generated certificate from the certificate store
$cert | Remove-Item -Force

# Re-Import the public key into the certificate store so we can use it in our DSC Configs
Import-Certificate -FilePath "$OutputPath\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My

