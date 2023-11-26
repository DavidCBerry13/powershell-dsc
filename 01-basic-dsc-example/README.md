# 01 - Basic DSC Example

This directory contains a very simple DSC Example to get started with.  

The DSC configuration is designed to:

- Set up a basic web server with IIS, ASP.NET, and a few IIS features
- Make sure a couple directories (*C:\logs* and *C:\perflogs*) are present on the target server

## Implementation Notes

A couple of important implementation notes:

- This DSC Config was tested against Windows Server 2022.  Older versions of Windows may not have .NET Framework available as a Windows Feature like Server 2022
- This configuration uses a target node of *localhost*, meaning the intent is that you:
  - Compile the configuration on your developer workstation
  - Copy the resulting MOF files to the target server
  - Run `Start-DscConfiguration` on the target server to configure that server
- This DSC Config uses the [PSDscResources](https://github.com/PowerShell/PSDscResources) module.  This means:
  - You need to install this module on your local workstation using an `Install-Module -Name PSDscResources`
  - Make sure this module is on the target server you deploy your DSC configuration to (see the [README](./README.md) at the root of the repo on options to do this)

## Deploying this Configuration

1. **Compile the DSC Configuration into a MOF file by running the PS1 file**

    Make sure that you are in a PowerShell 5.1 prompt when you compile the config.  Otherwise you will get a strange error about an ArrayList not being supported.

    ```PowerShell
    .\BasicDscExampleConfiguration.ps1
    ```

    The way the file is setup, two files (*localhost.mof* and *localhost.meta.mof*) will be created in the same directory as the DSC Config (PS1) file.

2. **Copy the Generated MOF files to the target server**

    Its a good idea to create a direcotry on the target server to contain these files.  In this example, I am going to create a directory called *C:\dsc-config* on the server and copy the files there.

3. **Copy the PSDscResources Module to the Target Server**

    If your server has Internet access, you could install the PSDscResources module from the PowerShell gallery.  But this example is practicing what is a more likely scenario, that a server has restricted Internet access and you want to automate the server build process in the future, so we'll copy over this module to the server.

    For this example, I am also assuming you are copying the needed folder via RDP to the target server.

    - Navigate to the ***C:\Program Files\WindowsPowerShell\Modules*** directory on your local workstation and find the *PsDscResources* folder
    - Copy this entire folder to the ***C:\Program Files\WindowsPowerShell\Modules*** directory on the target server

4. **Run the DSC Configuration on the Target Server**

    On the target server, open a PowerShell 5.1 prompt and run the following command (if you used a different directory than *C:\dsc-confg*, substitute that in instead for the `-Path`)

    ```PowerShell
    Start-DscConfiguration -Path C:\dsc-config\01-basic-config\ -Wait -Verbose -Force
    ```

    The DSC Configuration will run for a couple of minutes, mostly to install the required Windows Features.  It should not have to reboot your target server.

5. **Verify that DSC Configuration worked**

    Verify the following

    - The Windows Features are installed by using the `Get-WindowsFeature` cmdlet
    - The *C:\logs* and *C:\Perflogs* directories exist.
