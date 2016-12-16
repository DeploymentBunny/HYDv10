<#
Created:	 2015-02-06
Version:	 1.0
Author       Mikael Nystrom

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author.

Author - Mikael Nystrom
    Twitter: @mikael_nystrom
    Blog   : http://deploymentbunny.com
#>

Param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    $OSDAdapter0Net,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
    $OSDAdapter0SubnetMaskPrefix,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=2)]
    $DHCPScopeStart,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=3)]
    $DHCPScopeEnd,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=4)]
    $ScopeFQDN,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=5)]
    $ScopeDNS1,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=6)]
    $ScopeDNS2,
    
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=7)]
    $ScopeRouter
)

function ConvertTo-DottedDecimalIP
{
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [String]$IPAddress
  )
  
  process {
    Switch -RegEx ($IPAddress) {
      "([01]{8}.){3}[01]{8}" {
        return [String]::Join('.', $( $IPAddress.Split('.') | ForEach-Object { [Convert]::ToUInt32($_, 2) } ))
      }
      "\d" {
        $IPAddress = [UInt32]$IPAddress
        $DottedIP = $( For ($i = 3; $i -gt -1; $i--) {
          $Remainder = $IPAddress % [Math]::Pow(256, $i)
          ($IPAddress - $Remainder) / [Math]::Pow(256, $i)
          $IPAddress = $Remainder
         } )
      
        return [String]::Join('.', $DottedIP)
      }
      default {
        Write-Error "Cannot convert this format"
      }
    }
  }
}

function ConvertTo-Mask
{
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [Alias("Length")]
    [ValidateRange(0, 32)]
    $MaskLength
  )
  Process {
    return ConvertTo-DottedDecimalIP ([Convert]::ToUInt32($(("1" * $MaskLength).PadRight(32, "0")), 2))
  }
}

# Settinga variables
Write-Verbose "Create Vars"
$ScopeName = "$OSDAdapter0Net/$OSDAdapter0SubnetMaskPrefix"
$IPAddress = $OSDAdapter0Net;$IPByte = $IPAddress.Split(".");$IPAddressB = ($IPByte[0]+"."+$IPByte[1]+"."+$IPByte[2]) 
$ScopeStart = $DHCPScopeStart
$ScopeEnd = $DHCPScopeEnd
$ScopeSubnetMask =  (ConvertTo-Mask $OSDAdapter0SubnetMaskPrefix)
$ScopeDNS = """$ScopeDNS1"",""$ScopeDNS2"""

# Add the Scope
Write-Verbose "Add the Scope"
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $ScopeStart -EndRange $ScopeEnd -SubnetMask $ScopeSubnetMask
Start-Sleep 2

#Set Options on scope
Write-Verbose "Set Options on scope"
$ScopeID = Get-DhcpServerv4Scope | Where-Object -Property Name -Like -Value "$ScopeName"
Set-DhcpServerv4OptionValue -ScopeId $ScopeID.ScopeId -DnsDomain $ScopeFQDN -DnsServer $ScopeDNS1,$ScopeDNS2 -Router $ScopeRouter -Force
Start-Sleep 2
