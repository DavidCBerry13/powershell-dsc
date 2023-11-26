Configuration BasicDscExampleConfiguration
{
  # Use the PsDScResources module as the built in module has some oddities (like WindowsOptionalFeature using Enable/Disable instead of Present/Absent)
  Import-DscResource -ModuleName PSDscResources
    

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

# We'll output the MOF file to the same directory this Config file is in
$OutputPath = Split-Path -parent $PSCommandPath
BasicDscExampleConfiguration -OutputPath $OutputPath