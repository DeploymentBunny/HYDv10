Import-Module C:\setup\Functions\VIADeployModule.psm1 -Force
Import-Module C:\setup\Functions\VIAHypervModule.psm1 -Force
Import-Module C:\Setup\Functions\VIAUtilityModule.psm1 -Force

Move-Item -Path 'C:\Setup\DL\SC 2016 DPM' -Destination 'C:\Setup\TempISO\SC 2016 DPM'
Move-Item -Path 'C:\Setup\DL\SC 2016 OM' -Destination 'C:\Setup\TempISO\SC 2016 OM'
Move-Item -Path 'C:\Setup\DL\SC 2016 OR' -Destination 'C:\Setup\TempISO\SC 2016 OR'
Move-Item -Path 'C:\Setup\DL\SC 2016 VMM' -Destination 'C:\Setup\TempISO\SC 2016 VMM'
Move-Item -Path 'C:\Setup\DL\SQL 2014 Express SP1' -Destination 'C:\Setup\TempISO\SQL 2014 Express SP1'
Move-Item -Path 'C:\Setup\DL\SQL 2014 SP1' -Destination 'C:\Setup\TempISO\SQL 2014 SP1'
Move-Item -Path 'C:\Setup\DL\Windows ADK 10 1607' -Destination 'C:\Setup\TempISO\Windows ADK 10 1607'
Move-Item -Path 'C:\Setup\DL\Windows Server 2016' -Destination 'C:\Setup\TempISO\Windows Server 2016'

New-VIAISOImage -SourceFolder C:\Setup\TempISO -Destinationfile D:\HYDV10ISO\HYDV10.iso

Move-Item -Path 'C:\Setup\TempISO\Windows Server 2016' -Destination 'C:\Setup\DL\Windows Server 2016'
Move-Item -Path 'C:\Setup\TempISO\SC 2016 DPM' -Destination 'C:\Setup\DL\SC 2016 DPM'
Move-Item -Path 'C:\Setup\TempISO\SC 2016 OM' -Destination 'C:\Setup\DL\SC 2016 OM'
Move-Item -Path 'C:\Setup\TempISO\SC 2016 OR' -Destination 'C:\Setup\DL\SC 2016 OR'
Move-Item -Path 'C:\Setup\TempISO\SC 2016 VMM' -Destination 'C:\Setup\DL\SC 2016 VMM'
Move-Item -Path 'C:\Setup\TempISO\SQL 2014 Express SP1' -Destination 'C:\Setup\DL\SQL 2014 Express SP1'
Move-Item -Path 'C:\Setup\TempISO\SQL 2014 SP1' -Destination 'C:\Setup\DL\SQL 2014 SP1'
Move-Item -Path 'C:\Setup\TempISO\Windows ADK 10 1607' -Destination 'C:\Setup\DL\Windows ADK 10 1607'
