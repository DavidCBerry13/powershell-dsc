
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


    Import-DscResource -ModuleName PSDscResources
    Import-DscResource -ModuleName cChoco -ModuleVersion 2.6.0.0
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 9.0.0

    Node $ComputerName
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

        TimeZone TimeZoneExample
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZoneId
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