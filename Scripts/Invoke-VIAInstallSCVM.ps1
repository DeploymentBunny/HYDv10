<#
.SYNOPSIS
  
.DESCRIPTION
  
.EXAMPLE
  
#>
Param (
    [Parameter(Mandatory=$true,Position=0)]
    $SCVMSetup,

    [Parameter(Mandatory=$true,Position=1)]
    [ValidateSet("Full","Client","Agent")]
    $SCVMRole = "Full",

    [Parameter(Mandatory=$true,Position=2)]
    $SCVMMDomain,

    [Parameter(Mandatory=$true,Position=3)]
    $SCVMMSAccount,

    [Parameter(Mandatory=$true,Position=4)]
    $SCVMMSAccountPW,

    [Parameter(Mandatory=$true,Position=5)]
    $SCVMMProductKey,

    [Parameter(Mandatory=$true,Position=6)]
    $SCVMMUserName,
    
    [Parameter(Mandatory=$true,Position=7)]
    $SCVMMCompanyName,

    [Parameter(Mandatory=$true,Position=8)]
    $SCVMMBitsTcpPort,

    [Parameter(Mandatory=$true,Position=9)]
    $SCVMMVmmServiceLocalAccount,

    [Parameter(Mandatory=$true,Position=10)]
    $SCVMMTopContainerName,

    [Parameter(Mandatory=$true,Position=11)]
    $SCVMMLibraryDrive
)

switch ($SCVMRole)
{
    Full
    {
        #Create IniFile
        $unattendFile = New-Item "VMServer.ini" -type File -Force
        set-Content $unattendFile "[OPTIONS]"
        if(!($SCVMMProductKey -eq "NONE"))
        {
            add-Content $unattendFile "ProductKey=$SCVMMProductKey"
        }
        add-Content $unattendFile "UserName=$SCVMMUserName"
        add-Content $unattendFile "CompanyName=$SCVMMCompanyName"
        add-Content $unattendFile "BitsTcpPort=$SCVMMBitsTcpPort"
        add-Content $unattendFile "VmmServiceLocalAccount=$SCVMMVmmServiceLocalAccount"
        add-Content $unattendFile "TopContainerName=$SCVMMTopContainerName"
        add-Content $unattendFile "VMMServiceDomain=$SCVMMDomain"
        add-Content $unattendFile "VMMServiceUserName=$SCVMMDomain\$SCVMMSAccount"
        add-Content $unattendFile "VMMServiceUserPassword=$SCVMMSAccountPW"
        add-Content $unattendFile "CreateNewLibraryShare=1"
        add-Content $unattendFile "LibraryShareName=MSSCVMMLibrary"
        add-Content $unattendFile "LibrarySharePath=$SCVMMLibraryDrive\ProgramData\Virtual Machine Manager Library Files"
        add-Content $unattendFile "LibraryShareDescription=Virtual Machine Manager Library Files"
        add-Content $unattendFile "SqlMachineName=$env:COMPUTERNAME"
        add-Content $unattendFile "SqlInstanceName=MSSQLSERVER"
        Get-Content $unattendFile
    
        $Setup = $SCVMSetup
        $sArgument = "/server /i /f $unattendFile /IACCEPTSCEULA"
        & $setup $sArgument
        #Get-Item -Path $unattendFile | Remove-Item -Force -Verbose
    }
    Client
    {
    }
    Agent
    {
    }
    Default
    {
    }
}

