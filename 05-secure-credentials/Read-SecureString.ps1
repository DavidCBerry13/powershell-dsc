# Helper function to allow a user to enter a secure string, re-enter it and make sure they match.
# This is useful because you cannot see a secure string when typing it, so a typo would cause you 
# not to know the password or other secret that you are setting.

# From https://stackoverflow.com/questions/48809012/compare-two-credentials-in-powershell#48810852
# Safely compares two SecureString objects without decrypting them.
# Outputs $true if they are equal, or $false otherwise.
function Compare-SecureString {
    param(
      [Security.SecureString]
      $SecureString1,
  
      [Security.SecureString]
      $SecureString2
    )
    try {
      $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString1)
      $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString2)
      $length1 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr1,-4)
      $length2 = [Runtime.InteropServices.Marshal]::ReadInt32($bstr2,-4)
      if ( $length1 -ne $length2 ) {
        return $false
      }
      for ( $i = 0; $i -lt $length1; ++$i ) {
        $b1 = [Runtime.InteropServices.Marshal]::ReadByte($bstr1,$i)
        $b2 = [Runtime.InteropServices.Marshal]::ReadByte($bstr2,$i)
        if ( $b1 -ne $b2 ) {
          return $false
        }
      }
      return $true
    }
    finally {
      if ( $bstr1 -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
      }
      if ( $bstr2 -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
      }
    }
  }


$SecureString = Read-Host "Enter a secure password" -AsSecureString 
$RepeatSecureString = Read-Host "Re-enter a secure password" -AsSecureString
  
if ( Compare-SecureString -SecureString1 $SecureString -SecureString2 $RepeatSecureString) {
    Write-Host "Passwords match"
    return $SecureString
}
else {
    throw "Passwords do not match"
}
