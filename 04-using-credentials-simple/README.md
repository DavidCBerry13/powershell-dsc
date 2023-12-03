# 03 - Using Credential (Simple)

There are a number of reasons you might need to provide credentials (a password) to your DSC Configurations.  These include:

- You want to create a local user as part of your DSC Config
- You want to have a process in your DSC config run as a different user

This example shows the simplest way to provide credentials to a DSC script by passing the credentials into the Configuration to create a local user with a password.

> **WARNING!** The techniques in this example will result in the password appearing in clear text in the MOF file and are therefore insecure.  This example is just for learning purposes.  The next example will show how to securely pass credentials to servers using certificates.

## DSC Modules Used

| Module Name                                                                      | Version  | Install-Package Command                                | DSC Resource(s) |
|----------------------------------------------------------------------------------|----------|--------------------------------------------------------|-----------------|
| PSDesiredStateConfiguration                                                      | 1.1      | N/A (Built-in to PowerShell)                           | File            |
| [PSDscResources](https://github.com/PowerShell/PSDscResources)                   | 2.12.0.0 | `Install-Module -Name PSDscResource`                   | WindowsFeature  |
| [cChoco](https://docs.chocolatey.org/en-us/features/integrations#powershell-dsc) | 2.6.0.0  | `Install-Module -Name cChoco -RequiredVersion 2.6.0.0` | cChocoInstaller, cChocoPackageInstaller |
| [ComputerManagementDsc](https://github.com/dsccommunity/ComputerManagementDsc)   | 9.0.0    | `Install-Module -Name ComputerManagementDsc`           | User            |

## Implementation Notes

### PSCredential Parameter

The Configuration takes a parameter of type PSCredential for the credential

```PowerShell
param(
  [String[]]
  $ComputerName="localhost",
  
  [Parameter(Mandatory = $true)]
  [System.Management.Automation.PSCredential]
  $WebUserPasswordCredential
)
```

This is then later used in the configuration to create the *WebUser* local user

```PowerShell
User WebUser
{
    UserName = "WebUser"
    Ensure = "Present"
    FullName = 'WebUser Example User'
    Password = $WebUserPasswordCredential
    PasswordNeverExpires = $True
    PasswordChangeRequired  = $False
    PasswordChangeNotAllowed  = $True
}
```

There are a couple different ways that you can create a PSCredential object

- **By using the PowerShell `Get-Credential` cmdlet.**  This is suitable for interactive scenarios.
- **By using `New-Object System.Management.Automation.PSCredential` to create a PSCredential object by providing the username and the password as arguements.  This is suitable for command line or scripted scenarios.

### Using Get-Credential (interactive scenarios)

In the **Create-ConfigUsingCredentialsExampleConfiguration.ps1** helper script, you see an example of using `Get-Credential` to get a credential object.

```PowerShell
$WebUserCredential = Get-Credential -UserName "WebUser" -Message 'Enter Password for WebUser'
```

This specifies the username as *WebUser* and provides an appropriate message so the user knows what they are entering a credential for.  The PSCredential object (WebUserCredential) can then be passed into the DSCConfiguration for the credential parameter.

### Creating a New PSCredential object (command line and scripted scenarios)

In these cases, you can create a PSCredential object using the `New-Object` cmdlet.

```PowerShell
$WebUserCredential = New-Object System.Management.Automation.PSCredential ("WebUser", $WebUserPassword)
```

In this case, the password ($WebUserPassword) needs to be provide as a secure string.  To create a secure string from a plain text string, use the `ConvertTo-SecureString` cmdlet as follows.

```PowerShell
$WebUserPassword = ConvertTo-SecureString "MyPlainTextPassword" -AsPlainText -Force
```

### Allowing Plain Text Passwords in MOF files

By default, if you provide a credentail (password) in this way to a DSC Configuration, PowerShell will generate an error when you execute that configuration and not generate the MOF file.  This is because even though you provide the password as a secure string or through a secure dialog box, it must be persisted in the MOF file as plain text.  PowerShell generates an error so you don't accidently do something insecure.

You can override this behavior though by providing configuration data to your DSC Config saying it is OK to store plain text credentials in your MOF files.  This should only be used for learning purposes and exploration, not in a production scenario.  What you do is create a config as follows:

```PowerShell
$configData = @{
    AllNodes = @(
        @{
        NodeName = $ComputerName
        PSDscAllowDomainUser = $true
        PSDscAllowPlainTextPassword = $true
    })
}
```

- The `ComputerName` in the NodeName attribute needs to match the Computer name you are going to use in your configuration.  
- If you are generating a config for multilpe computers, then have a node config block for each computer.  Using `NodeName = "*"` does not seem to work as an error is still generated.  

Then, when you execute your config, you pass this config data to the DSC configuration using the `-ConfigurationData` parameter.

```PowerShell
ConfigUsingCredentialsExampleConfiguration -OutputPath $OutputPath -ComputerName $ComputerName -WebUserPasswordCredential $WebUserCredential -ConfigurationData $configData
```

## References

- [Add Credential support to PowerShell Functions](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/add-credentials-to-powershell-functions?view=powershell-5.1)