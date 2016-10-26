<#
 # Will write to registry to signal Hyper-V host that TaskSequence is done
#>

New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest' -Name TaskSequence -Value Done -PropertyType String
