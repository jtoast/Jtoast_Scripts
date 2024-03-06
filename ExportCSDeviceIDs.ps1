

#This script when finished will export a list of active machines from both AD and the Crowdstrike console and then compare.
#Written by Jim Roberts 03/04/2024


#Import powershell module so we don't have to deal with restAPI auth and formatting.
Import-Module -Name PSFalcon

$outputPath = "C:\temp\Delta_$((Get-Date).ToString('MMddyyyy_hh:mm:ss')).csv"



Function GetCSToken {
    try {
        Write-host "Attempting to acquire Falcon Token"
        #Grab an authentication token. Will require you to paste in api client and secret until I add an auth method.
        Request-FalconToken
        if ((Test-FalconToken).Token -eq $true) { 
            Write-host "Successfully retrieved Falcon Token"
        }
    }
    catch {
        Write-host $Error
        Write-host "Failed to acquire Falcon Token. Exiting script"
        Exit
    }
}

Function RetrieveCSHosts {
    try {
        #Pull list of CrowdStrike hostnames
        Write-host "Attempting to acquire hostnames from CrowdStrike Cloud. Grab some coffee, this part could take up to 3 minutes to complete."
                $script:falconHostList = Get-Falconhost -Detailed | select-object hostname 
        Write-host "Successfully retrieved host info from the Crowdstike Cloud"
            }

    catch {
        Write-host $Error
        Write-host "Failed to acquire Falcon hosts info. Exiting script"
       
    }
}

Function RetrieveADHosts {
    try {
        #pull list of AD Hostnames
        
        Write-Host "Attempting to retrieve hostnames from AD"
        
        $script:adHostList = Get-ADComputer -filter "Enabled -eq 'true'" | Select-Object Name 
        
        Write-host "Succesfully retrieved AD host info"
        
    }
    catch {
        Write-host $Error
        Write-host "Failed to acquire Active host from Active Directory. Exiting script"
    }
}


Function CompareResults {
    try {
        
        # Compare the contents of the comparison CSV file against the master CSV file based on a specific property
        Write-Host "Beginning Crowdstrike/AD comparison."
        $Script:uniqueRows = Compare-Object -ReferenceObject $adHostList -DifferenceObject $falconHostList -Property 'ColumnA' -PassThru | Where-Object { $_.SideIndicator -eq '<=' } 
        Write-Host "Crowdstrike AD Comparison complete. Beginning export"
        
    }

    catch {
        Write-host $Error
        Write-host "An issue occured when attempting to compare data source. exiting script "
    }
    
}


############################Do Stuff###############################
GetCSToken

RetrieveCSHosts


RetrieveADHosts


CompareResults

#export Results
Try {
    # Export the unique rows to a new CSV file
    Write-Host "Exporting results to CSV"
    $uniqueRows | Export-Csv -Path $outputPath -NoTypeInformation
    Write-host "Hostnames in AD but not in CS have been exorted to $outputPath."
    Write-Host  "Exiting Script"
}


Catch {
    Write-Host $Error
    Write-host "Export to CSV failed."
    Write-host "Exiting Script."
    exit
}