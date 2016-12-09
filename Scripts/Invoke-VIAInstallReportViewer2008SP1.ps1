<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $Source
 )

Try
    {
    Write-Verbose "Installing $Source" 
    Start-Process -FilePath "$Source" -ArgumentList '/q' -Wait -NoNewWindow
    }
Catch
    {
      $ErorMsg = $_.Exception.Message
      Write-Warning "Error during script: $ErrorMsg"
      Break
    }
