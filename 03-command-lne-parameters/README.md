# 03 - Command Line Parameters Example

It is useful to be able to paramaterize your DSC configurations so you can use the same configuration on different servers, passing in the parameters of what needs to be changd on each server.  This example is based on passing in a timezone value so the same config can be used on different servers in different timezones.  The timezone can be set by using the [ComputerManagementDsc](https://github.com/dsccommunity/ComputerManagementDsc) module.

## Implementation Notes

The [Add Parameters to a Configuration](https://learn.microsoft.com/en-us/powershell/dsc/configurations/add-parameters-to-a-configuration?view=dsc-1.1) article on Microsoft Learn gives an overview of how to add parameters to a DSC configuration.  

### Microsoft Learn Approach

In the Microsoft Learn article, it is assumed that:

- You only have your configuration element in the DSC ps1 file

    ```PowerShell
    Configuration SomeConfiguration
    {
        param(
            [String]
            $MyParam
        )

        # Remainder of config removed for brevity
    }
    ```

- You then load that configuration into your PowerShell environment

    ```PowerShell
    . .\SomeConfiguration.ps1
    ```

- You then execute the configuration by calling the config block with the parameter and pass in its value (in this case 'ABC')

```PowerShell
SomeConfiguration -MyParam "ABC"
```

### Approach of this example

This example varies slightly from the Microsoft Learn approach because at the bottom of the PS1 DSC Configuration file, I have code to execute the configuration.

```PowerShell
$OutputPath = Split-Path -parent $PSCommandPath
CommandLineParametersExampleConfiguration -TimeZone $TimeZoneId -OutputPath $OutputPath
```

I did this because to me, it feels more natural just to run a script and have it generate the configuration.  As such, I need to specify the parameter three places.

- At the top of my PS1 file file.  This is what grabs the parameter off the commadn line
- In the DSC Configuration as in the Microsoft Learn article
- In the call to execute the configuration at the bottom of the file (as shown above)

This approach feels like it could be a little redundant and I may end up changing it as I work with DSC more.  But for now, I wanted to document what I did and how I got it to work.  One thing that was confusing is that at first, it did not seem like th econfig was picking up the parameter I was passing in as part of my command line.  That is because it was not: The parameter was inside the Configuration block and was not being provided when I executed the Config block.  I had forgotten about calling the COnfig block at the bottom.  This is why my example did not work like the Microsoft Learn example.
