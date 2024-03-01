# This script will pull active machines from the AD console and the Crowdstrike console. it will eventually compare them unless I run out of time.
#Written by Jim Roberts
#02/28/2024


#Authentication will be added in later.


#Get active computer name ad.
    Get-ADComputer -filter "Enabled -eq 'true'" -properties canonicalname,operatingsystem,LastLogonDate | Select-Object name,canonicalname,operatingsystem,LastLogonDate | Export-CSV c:\temp\computers.csv -NoTypeInformation
   

