# 03 - Command Line Parameters Example

It is useful to be able to paramaterize your DSC configurations so you can use the same configuration on different servers, passing in the parameters of what needs to be changd on each server.  This example is based on passing in a timezone value so the same config can be used on different servers in different timezones.  The timezone can be set by using the [ComputerManagementDsc](https://github.com/dsccommunity/ComputerManagementDsc) module.

| Module Name                                                                      | Version  | Install-Package Command                                | DSC Resource(s) |
|----------------------------------------------------------------------------------|----------|--------------------------------------------------------|-----------------|
| PSDesiredStateConfiguration                                                      | 1.1      | N/A (Built-in to PowerShell)                           | File            |
| [PSDscResources](https://github.com/PowerShell/PSDscResources)                   | 2.12.0.0 | `Install-Module -Name PSDscResource`                   | WindowsFeature  |
| [cChoco](https://docs.chocolatey.org/en-us/features/integrations#powershell-dsc) | 2.6.0.0  | `Install-Module -Name cChoco -RequiredVersion 2.6.0.0` | cChocoInstaller, cChocoPackageInstaller |
| [ComputerManagementDsc](https://github.com/dsccommunity/ComputerManagementDsc)   | 9.0.0    | `Install-Module -Name ComputerManagementDsc`           | TimeZone        |

## Implementation Notes

The [Add Parameters to a Configuration](https://learn.microsoft.com/en-us/powershell/dsc/configurations/add-parameters-to-a-configuration?view=dsc-1.1) article on Microsoft Learn gives an overview of how to add parameters to a DSC configuration.  

The example uses that approach to accept two parameters

- A list of computer names to generate the conficguration for (exactly the same as the article)
- A user supplied TimeZoneId of the timezone to set on the computers in the configuration

Parameters are defined just after the start of the configuration block using the `param` keyword.  You can use standard PowerShell param atributes to cotnrol the type of a parameter, make it mandatory, validate the parameter, or provide a default value.

```PowerShell
Configuration CommandLineParametersExampleConfiguration
{
    param(
      [String[]]
      $ComputerName="localhost",      
      
      [Parameter(Mandatory = $true)]
      [String]
      [ValidateSet("Eastern Standard Time",
          "Central Standard Time",
          "Mountain Standard Time",
          "Pacific Standard Time",
          "Alaskan Standard Time",
          "Hawaiian Standard Time",
          "US Mountain Standard Time")]
      $TimeZoneId
    )

    # Remainder of DSC Config removed for brevity
}
```

For the `$ComputerName` parameter, a user can supply one or more computer names, and then MOF files for each of those computers will be generated in the *output* directory.  If the user does not supply a value for `$ComputerName` then localhost will be used.

For the `$TimeZoneId` property, the user needs to provide a TimeZoneId of a US timezones from the validation set defined for the parameter.  I included this as an example since often it is the case that we want the user to provide one of a predefined set of values.  The actual timezone ids correspond to what PowerShell returns from its `Get-Timezone -ListAvailable` command.  This acceptable list for this config is simply trimmed down to US timezones.

## Helper Script

In all of my examples so far, I have provided a helper script to generate the configuration and I do so in this example as well.  The purpose in providng this helper script is because to me it feels more natural to run a script and have the configuration generate rather than dot sourcing the config into my PowerShell environment and the executing the config.  Under the hood this is what the helper script does, just through a script.

Passng parameters has some implications for my helper script.  First, the script now has to accept parameters.  In the case of timezone, I actually accept simplified string names of each US timezone and then translate that to the PowerShell TimeZoneId.  This makes it a little easier for a user to type and get the names right.  The downside is that the script and the config now have to stay in sync.

I still think providing a script makes sense as it can provide a simpler front-end to DSC configurations.  There is a cost though of making sure things stay in sync.
