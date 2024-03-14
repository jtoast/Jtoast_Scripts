#This script when finished will export a list of active machines from both AD and the Crowdstrike console and then compare.
#Written by Jim Roberts 03/04/2024.

#Start by setting up some logging.
 # Check if the directory C:\Temp exists, if not, create it
 $TempDirectory = "C:\Temp"
 if (-not (Test-Path -Path $TempDirectory -PathType Container)) {
     New-Item -Path $TempDirectory -ItemType Directory
 }
 $Logpath= $TempDirectory
 $LogName = "ADCSCompare_$((Get-Date).ToString("MMddyy HHmmss"))_.log"
 $Logfile = Join-Path $Logpath $LogName

 function WriteLog {
    Param ([string]$LogString)
    
    $TimeLog = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$TimeLog $LogString"
    Add-Content $LogFile -Value $LogMessage
}
Writelog "Starting Script"

#Import powershell module so we don't have to deal with restAPI auth and formatting.
Import-Module -Name PSFalcon

$outputPath = "C:\temp\Delta_$((Get-Date).ToString("MMddyy HHmm"))_.csv"



Function GetCSToken {
    try {
        Write-host "Attempting to acquire Falcon Token"
        WriteLog  "Attempting to acquire Falcon Token"
        #Grab an authentication token. Will require you to paste in api client and secret until I add an auth method.
        Request-FalconToken
        if ((Test-FalconToken).Token -eq $true) { 
            Write-host "Successfully retrieved Falcon Token"
            WriteLog "Successfully retrieved Falcon Token"
        }
    }
    catch {
        Write-host $Error
        Write-host "Failed to acquire Falcon Token. Exiting script"
        WriteLog "Failed to acquire Falcon Token. Exiting script"
        Exit
    }
}

Function RetrieveCSHosts {
    try {
        #Pull list of CrowdStrike hostnames
        Write-host "Attempting to acquire hostnames from CrowdStrike Cloud. Grab some coffee, this part could take up to 3 minutes to complete."
        WriteLog "Attempting to acquire hostnames from CrowdStrike Cloud. Grab some coffee, this part could take up to 3 minutes to complete."

                $script:falconHostList = Get-Falconhost -Detailed | select-object hostname 
        Write-host "Successfully retrieved host info from the Crowdstike Cloud"
        WriteLog "Successfully retrieved host info from the Crowdstike Cloud"
            }

    catch {
        Write-host $Error
        Write-host "Failed to acquire Falcon hosts info. Exiting script"
        WriteLog $Error
        WriteLog "Failed to acquire Falcon hosts info. Exiting script"
       
    }
}

Function RetrieveADHosts {
    try {
        #pull list of AD Hostnames
        
        Write-Host "Attempting to retrieve hostnames from AD"
        WriteLog "Attempting to retrieve hostnames from AD"
        
        $script:adHostList = Get-ADComputer -filter "Enabled -eq 'true'" | Select-Object Name 
        
        Write-host "Succesfully retrieved AD host info"
        WriteLog "Succesfully retrieved AD host info"
        
    }
    catch {
        Write-host $Error
        Write-host "Failed to acquire Active host from Active Directory. Exiting script"
        WriteLog $Error
        WriteLog "Failed to acquire Active host from Active Directory. Exiting script"
    }
}


Function CompareResults {
    try {
        
        # Compare the contents of the comparison CSV file against the master CSV file based on a specific property
        Write-Host "Beginning Crowdstrike/AD comparison."
        WriteLog "Beginning Crowdstrike/AD comparison."

        $Script:uniqueRows = Compare-Object -ReferenceObject $adHostList -DifferenceObject $falconHostList -Property 'ColumnA' -PassThru | Where-Object { $_.SideIndicator -eq '<=' } 
        Write-Host "Crowdstrike AD Comparison complete. Beginning export"
        WriteLog "Crowdstrike AD Comparison complete. Beginning export"
        
    }

    catch {
        Write-host $Error
        Write-host "An issue occured when attempting to compare data source. exiting script"
        WriteLog $Error
        WriteLog "An issue occured when attempting to compare data source. exiting script"
        Exit
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
    WriteLog Write-Host "Exporting results to CSV"
    $uniqueRows | Export-Csv -Path $outputPath -NoTypeInformation
    Write-host "Hostnames in AD but not in CS have been exported to $outputPath."
    WriteLog "Hostnames in AD but not in CS have been exported to $outputPath."
    Write-Host  "Exiting Script"
    WriteLog "Exiting Script"
    Exit
}


Catch {
    Write-Host $Error
    Write-host "Export to CSV failed."
    Write-host "Exiting Script."
    WriteLog $Error
    WriteLog "Export to CSV failed.
    WriteLog Exiting Script"
    exit
}
