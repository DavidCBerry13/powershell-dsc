# 02 - Chocolatey Software Install Example

Almost any system you install is going to need software on it.  These might just be basic utilities like [Notepad++](https://notepad-plus-plus.org/) and [7-Zip](https://7-zip.org/), but in any case, you want an easy way to install, maintain, and update this software when neccessary. 

[Chocolatey](https://docs.chocolatey.org/en-us/) is a package manager for Windows, similar to [apt](https://en.wikipedia.org/wiki/APT_(software)) or [yum](https://en.wikipedia.org/wiki/Yum_(software)) on Linux system.  Rather than installing an MSI, applications are installed through Chocolatey.  In this way, they can be managed through the Chocolatey command line ([choco](https://docs.chocolatey.org/en-us/choco/commands/)) which can show you what packages (apps) are out of date and allows you to easily update those apps to the latest version.

Chocolatey also has a DSC module, [cChoco](https://docs.chocolatey.org/en-us/features/integrations#powershell-dsc) that enables apps to be managed through a DSC configuration.  This example uses the cChoco module to install Chocolatey and then intstall Notepad++, 7-Zip, and Process Explorer.  In this example, these packages are installed from the [Chocolatey Community package repository](https://community.chocolatey.org/packages).  In a corporate scenario, you would set up your own internal package repository and point your DSC configuration at your internal repository.

## Implementation Notes

- You must use cChcoco version 2.6.0.0 or higher.  Version 2.5.0 and below seems to have a bug such that it does not work on Windows 2022.
  - The commands below assume usage of 2.6.0.0.  If you use a later version of cChoco, you will need to either also install version 2.6.0.0 or modify the commands below.
- This example uses both the cChoco and [PSDscResources](https://github.com/PowerShell/PSDscResources) module.  As such, both modules need to be copied to the target server
- After the DSC configuration runs, it seems that the `choco` CLI does not work in a PowerShell window as it is not in the path.  Rebooting fixes this problem (though there is probably a less dramatic way).  After a reboot, commands like `choco list` work just fine.

## Using the cChoco package to manage software via DSC

There are four items that you will need to include in your DSC configuration.

- Install the cChoco DSC Package
- Import the cChoco Module in your DSC Configuration
- Install Chocolatey using the cChocoInstaller element
- Install the desired app(s) using the cChocoPackageInstaller element

1. **Install the cChoco DSC Package**

    ```PowerShell
    Install-Module -Name cChoco -RequiredVersion 2.6.0.0
    ```

2. **Import the cChoco Module in your DSC Configuration**

    At the top of your DSC Configuration, right after you configuration element, you need to import the cChcoco package

    ```PowerShell
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.6.0.0
    ```

3. **Install Chocolatey using the cChocoInstaller element**

    For Chocolatey to install software, you need to install Chocolatey itself.  The cChocoInstaller element is designed for this purpose.

    This command installs Chocolatey to the C:\ProgramData\chocolatey folder (which is standard if you just downloaded and installed Chocolatey on your system).  Note that C:\ProgramData\ is a hidden folder, so to see what is in the folder you need to navigate directly to it.

    ```PowerShell
    cChocoInstaller InstallChocolatey
    {
        InstallDir = "c:\ProgramData\chocolatey"
    }
    ```

4. **Install the desired app(s) using the cChocoPackageInstaller element**

    Use cChocoPackageInstaller to install specific packages (apps).  There would be one of these configuration elements for each package you wanted installed on a system.

    - Note how this element contains a `DependsOn` element pointing to the Chocolately installation
    - If using an internal repository, you would include the `Source` parameter to specify the location of the internal repository

    ```PowerShell
    cChocoPackageInstaller InstallNotepadPlusPlus
    {
        Name     = "notepadplusplus"
        Version  = "8.6.0"
        DependsOn = "[cChocoInstaller]InstallChocolatey"
    }
    ```

## cChoco DSC Resouce Reference

### cChocoInstaller

#### cChocoInstaller Parameters

This is generated using a `Get-DscResource cChocoInstaller | Select -ExpandProperty Properties` command

```Text
Name                  PropertyType   IsMandatory Values
----                  ------------   ----------- ------
InstallDir            [string]              True {}
ChocoInstallScriptUrl [string]             False {}
DependsOn             [string[]]           False {}
PsDscRunAsCredential  [PSCredential]       False {}
```

#### cChocoInstaller Syntax

This is generated using a `Get-DscResource -Name cChocoInstaller -Syntax` command

```PowerShell
cChocoInstaller [String] #ResourceName
{                                                                                                                           
    InstallDir = [string]
    [ChocoInstallScriptUrl = [string]]
    [DependsOn = [string[]]]
    [PsDscRunAsCredential = [PSCredential]]
}
```

### cChocoPackageInstaller

#### cChocoPackageInstaller Parameters

This is genrated from the `Get-DscResource cChocoPackageInstaller | Select -ExpandProperty Properties` command

```Text
Name                 PropertyType   IsMandatory Values
----                 ------------   ----------- ------
Name                 [string]              True {}
AutoUpgrade          [bool]               False {}
chocoParams          [string]             False {}
DependsOn            [string[]]           False {}
Ensure               [string]             False {Absent, Present}
MinimumVersion       [string]             False {}
Params               [string]             False {}
PsDscRunAsCredential [PSCredential]       False {}
Source               [string]             False {}
Version              [string]             False {}
```

#### cChocoPackageInstaller Syntax

This is generated from the `Get-DscResource -Name cChocoPackageInstaller -Syntax` command

```PowerShell
cChocoPackageInstaller [String] #ResourceName
{                                                                                                                           
    Name = [string]                                                                                                         
    [AutoUpgrade = [bool]]
    [chocoParams = [string]]
    [DependsOn = [string[]]]
    [Ensure = [string]{ Absent | Present }]
    [MinimumVersion = [string]]
    [Params = [string]]
    [PsDscRunAsCredential = [PSCredential]]
    [Source = [string]]
    [Version = [string]]
}
```
