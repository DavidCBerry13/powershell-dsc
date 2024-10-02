# 05 - Secure Credentials

The previous example was able to onclude credentials in the MOF file but these credentials were in plain text in the MOF file.  A better approach is to be encrypt the credentials using a public/private key certificate, which is what this example does.  

In this example, you:

- Generate a Self-Signed certificate using PowerShell suitable for encrypting and decrypting credentials in DSC configurations.
- Use the public key of the certificate to encrypt credentials when executing your DSC Configuration on your development workstation
- Load the private key of the certificate to the target node so the target node can decrypt the credentials in the MOF file
- Update the Local Configuration Manager (LCM) config of the target server so it knows a certificate is available
- Deploy the DSC configuration to the target server (where the credentials will be decrypted and used)

This is the preferred approach to securing credentials in DSC Configs.  This example goes through the steps manually though these steps could easily be adapted to an automated devops approach.

## DSC Modules Used

| Module Name                                                                      | Version  | Install-Package Command                                | DSC Resource(s) |
|----------------------------------------------------------------------------------|----------|--------------------------------------------------------|-----------------|
| PSDesiredStateConfiguration                                                      | 1.1      | N/A (Built-in to PowerShell)                           | File            |
| [PSDscResources](https://github.com/PowerShell/PSDscResources)                   | 2.12.0.0 | `Install-Module -Name PSDscResource`                   | WindowsFeature  |
| [cChoco](https://docs.chocolatey.org/en-us/features/integrations#powershell-dsc) | 2.6.0.0  | `Install-Module -Name cChoco -RequiredVersion 2.6.0.0` | cChocoInstaller, cChocoPackageInstaller |
| [ComputerManagementDsc](https://github.com/dsccommunity/ComputerManagementDsc)   | 9.0.0    | `Install-Module -Name ComputerManagementDsc`           | User            |

## Implementation Notes

### Creating the Certificate

First, you need a certificate to be able to encrypt your credentials.  A helper script (Create-Certificate.ps1) is included in this folder to make it easier to create the appropriate certificate.  According to the Microsoft Docs article [Securing the MOF File](https://learn.microsoft.com/en-us/powershell/dsc/pull-server/securemof), the [certificate must meet these requirements](https://learn.microsoft.com/en-us/powershell/dsc/pull-server/securemof?view=dsc-1.1#certificate-requirements)

- The **Key Usage** of the certificate must contain *KeyEncipherment* and *DataEncipherment*
- The **Key Usage** should not contain *Digital Signature*
- **Enhanced Key Usage** must contain *Document Encryption (1.3.6.1.4.1.311.80.1)*
- **Enhanced Key Usage** should not contain *Client Authentication (1.3.6.1.5.5.7.3.2)* or *Server Authentication (1.3.6.1.5.5.7.3.1)*
- The **Provider** must be *Microsoft RSA SChannel Cryptographic Provider*

The article *Securing the MOF File* provides sample PowerShell to create a certificate.  However, the sample code in teh article does not explicitely set the **Enhanced Key Usage** property to *Digital Signature*.  The GitHub repo [https://github.com/nanalakshmanan/xDSCUtils/blob/master/xDSCUtils.psm1](https://github.com/nanalakshmanan/xDSCUtils/blob/master/xDSCUtils.psm1) provides an example of how to do this.  

These two examples were combined to create the `Create-Certificate.ps1` script in this folder.  In addition to creating the certificate, the script:

- Outputs the private key to a file named `DscPrivateKey.pfx` in the certificates directory
- Outputs the public key to a file named `DscPublicKey.cer` in the certificates directory
- Outputs the thumbprint of the private key to a file named `thumbprint.txt` in the certificates directory
- Removed the full certificate from the certificate store in Windows (where PowerShell places it by default)
- Reloads the public key certificate back into the certificate store

To create the certificate, simply run the `Create-Certificate.ps1` script as follows.  Be sure to note the private key password as you will need it later.

```PowerShell
.\Create-Certificate.ps1 -PfxPassword "PRIVATE_KEY_PASSWORD"
```

From here, you will need to copy the private key pfx file (`DscPrivateKey.pfx`) to the target node(s) and import it into the certificate store on those nodes.  To import the private key certificate, you will need to provide the private key password as a secure string.  Then, you will use the `Import-PfxCertificate` cmdlt to import the certificate to the certificate store on the target node.  The following code demonstrates how to do this.

```PowerShell
$privateKeyPassword = ConvertTo-SecureString -String "PRIVATE_KEY_PASSWORD" -Force -AsPlainText
Import-PfxCertificate -FilePath "C:\dsc-config\certificate\DscPrivateKey.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $privateKeyPassword
```

> WARNING: Protect the pfx file.  Anyone with the pfx file can decrypt the credentials, so you want to make sure this file is stored securly.  After loading the private key on the target node, delete the pfx file so it is not accidently left available for someone else to obtain.

### Using the public key to encrypt credentials when generating the configuration

Similar to example #4, the DSC Configuration takes a parameter for the credentials which in this case are used as the password for the local user *WebUser*.

```PowerShell
param(
  [String[]]
  $ComputerName="localhost",
  
  [Parameter(Mandatory = $true)]
  [System.Management.Automation.PSCredential]
  $WebUserPasswordCredential
)
```

The key to using encrypted credentials with a certificate is in the configuration data used when you execute the DSC Configuration to generate a MOF file.  In the `Create-CredentialsUsingCertificateExampleConfiguration.ps1`, you see the following loop that generates the config data used when the DSC config is executed.

```PowerShell
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
```

Critically, this config data contains two things:

- The **CertificateFile** property is set to the path of the public key of the certificate we just generated.  This is used to encrypt the crednetials in the generated MOF file.
- The **Thumbprint** property set to the Thumbprint of the certificate.  This value will get passed to the Local Config Manager (LCM) Config in the DSC Configuration file and is used on the target node to know what certificate to use to decrypt the credentials.

The second important element is back in your DSC Configuration file (in this case `CredentialsUsingCertificateExampleConfiguration.ps1`), you need to update the LCM Config section as follows:

```PowerShell
# LCM Configuration
LocalConfigurationManager 
{
  RebootNodeIfNeeded     = $True
  ConfigurationMode      = "ApplyAndAutoCorrect"
  ActionAfterReboot      = "ContinueConfiguration"
  RefreshMode            = "Push"
  CertificateId          = $node.Thumbprint
}
```

Notice the last property **CertificateId**.  It uses the value of the Thumbprint provide in the config data.  This is how the target node will know what cert to use to decrypt the data.

From here, run the script `Create-CredentialsUsingCertificateExampleConfiguration.ps1` and it should generate the MOF files like normal.

```PowerShell
.\Create-CredentialsUsingCertificateExampleConfiguration.ps1 -WebUserPassword "WEB_USER_PASSWORD"
```

### Deploying a Configuration with Encrypted Credential Data

1. **Copy the MOF files to the target server**

    Now that you have the MOF files, copy them to the target node as usual.

2. **Update the Local Configuration Manager (LCM) Settings**

    On the target node, the first thing you need to do is to update the Local Configuration Manager (LCM) settings.  

    ```PowerShell
    Set-DscLocalConfigurationManager C:\dsc-config\05-secure-credentials -Verbose -Force
    ```

    This loads the localhost.meta.mof file to be used as the LCM settings and lets the LCM know the Thumbprint of the cert it should use when it needs to decrypt credentials.

    You can verify the LCM has the right thumbprint by running the `Get-DscLocalConfigurationManager` command

    ```PowerShell
    Get-DscLocalConfigurationManager
    ```

3. **Invoke the configuration on the target server**

    Lastly, just run `Start-DscConfiguration` like you normally would for any other config.

    ```PowerShell
    Start-DscConfiguration C:\dsc-config\05-secure-credentials -wait -verbose -force
    ```

## Resources

- [Securing MOF Files with Certificates](https://learn.microsoft.com/en-us/powershell/dsc/pull-server/securemof?view=dsc-1.1)
- [Want to Secure Credentials using PowerShell Desired State Configuration](https://devblogs.microsoft.com/powershell/want-to-secure-credentials-in-windows-powershell-desired-state-configuration/)