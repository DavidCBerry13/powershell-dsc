Configuration ChocoSoftwareInstallExampleConfiguration
{
    # Use the PsDScResources module as the built in module has some oddities (like WindowsOptionalFeature using Enable/Disable instead of Present/Absent)
    Import-DscResource -ModuleName PSDscResources
    # We need at least cChoco version 2.6.0.0 because 2.5.0.0 had a bug to where it does not work on Windows Server 2022
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.6.0.0

    Node "localhost"
    {

        WindowsFeature WebServer
        {
          Name = "Web-Server"
          Ensure = "Present"
        }

        WindowsFeature ManagementTools
        {
          Name = "Web-Mgmt-Tools"
          Ensure = "Present"
        }

        WindowsFeature DefaultDoc
        {
          Name = "Web-Default-Doc"
          Ensure = "Present"
        }

        WindowsFeature WebStaticCompression
        {
          Name = "Web-Stat-Compression"
          Ensure = "Present"
        }

        WindowsFeature WebDynamicCompression
        {
          Name = "Web-Dyn-Compression"
          Ensure = "Present"
        }

        WindowsFeature DotNetFramework48
        {
          Name = "NET-Framework-45-Core"
          Ensure = "Present"
        }

        WindowsFeature DotNetFrameworkAspNet48
        {
          Name = "NET-Framework-45-ASPNET"
          Ensure = "Present"
        }
  
        #Create C:\Logs folder
        File LogsDirectory 
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\Logs"
        }
  
        #Create C:\PerfLogs folder
        File PerflogsDirectory 
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\PerfLogs"
        }

        # Before installing any packages, you need to install Chocolatey itself (this does the to C:\choco directory)
        cChocoInstaller InstallChocolatey
        {
            InstallDir = "c:\ProgramData\chocolatey"
        }

        # Install NorePad++ - Because every system needs a decent text editor
        cChocoPackageInstaller InstallNotepadPlusPlus
        {
            Name     = "notepadplusplus"
            Version  = "8.6.0"
            DependsOn = "[cChocoInstaller]InstallChocolatey"
        }

        # Install 7-Zip - Because every system needs a decent zip tool
        cChocoPackageInstaller Install7Zip
        {
            Name     = "7zip"
            Version  = "23.1.0"
            DependsOn = "[cChocoInstaller]InstallChocolatey"
        }

        # Install Process Explorer - Because every system should have a Process Explorer to troubleshoot issues
        cChocoPackageInstaller InstallProcessExplorer
        {
            Name     = "procexp"
            Version  = "17.5.0.20231021"
            DependsOn = "[cChocoInstaller]InstallChocolatey"
        }

        # LCM Configuration
        LocalConfigurationManager 
        {
          RebootNodeIfNeeded     = $True
          ConfigurationMode      = "ApplyAndAutoCorrect"
          ActionAfterReboot      = "ContinueConfiguration"
          RefreshMode            = "Push"
      }


    }
}
