#This script gathers list of active machines from both AD and the Crowdstrike console, compares the two, and exports a list of machines in AD that are not in the CS console.
#Written by Jim Roberts 03/04/2024

# Set the error action preference to stop on error
$ErrorActionPreference = "Stop"

# Import the PSFalcon module
Import-Module -Name PSFalcon

# Check if the directory C:\Temp exists and set a few variables
$Logpath = "C:\Temp"
if (!(Test-Path -Path $Logpath -PathType Container)) {
    New-Item -Path $Logpath -ItemType Directory
}

$LogName = "ADCSCompare_$((Get-Date).ToString("MMddyy HHmmss"))_.log"
$LogFile = Join-Path $Logpath $LogName

function WriteLog {
    Param ([string]$LogString)
    
    $TimeLog = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$TimeLog $LogString"
    Add-Content $LogFile -Value $LogMessage
}

WriteLog "Starting Script"

$outputPath = "C:\temp\Delta_$((Get-Date).ToString("MMddyy HHmm"))_.csv"

Function GetCSToken {
    try {
        Write-Host "Attempting to acquire Falcon Token"
        WriteLog  "Attempting to acquire Falcon Token"
        # Grab an authentication token. Will require you to paste in api client and secret until I add an auth method.
        Request-FalconToken
        if ((Test-FalconToken).Token -eq $true) { 
            Write-Host "Successfully retrieved Falcon Token"
            WriteLog "Successfully retrieved Falcon Token"
        }
    }
    catch {
        Write-Host $Error
        WriteLog $Error
        Write-Host "Failed to acquire Falcon Token. Exiting script"
        WriteLog "Failed to acquire Falcon Token. Exiting script"
        Exit
    }
}

Function RetrieveCSHosts {
    try {
        # Pull list of CrowdStrike hostnames
        Write-Host "Attempting to acquire hostnames from CrowdStrike Cloud. Grab some coffee, this part could take up to 3 minutes to complete."
        WriteLog "Attempting to acquire hostnames from CrowdStrike Cloud. Grab some coffee, this part could take up to 3 minutes to complete."

        $script:falconHostList = Get-Falconhost -Detailed | select-object hostname 
        Write-Host "Successfully retrieved host info from the Crowdstrike Cloud"
        WriteLog "Successfully retrieved host info from the Crowdstike Cloud"
    }
    catch {
        Write-Host $Error
        WriteLog $Error
        Write-Host "Failed to acquire Falcon hosts info. Exiting script"
        WriteLog "Failed to acquire Falcon hosts info. Exiting script"
        Exit
    }
}

Function RetrieveADHosts {
    try {
        # Pull list of AD Hostnames
        Write-Host "Attempting to retrieve hostnames from AD"
        WriteLog "Attempting to retrieve hostnames from AD"
        
        $script:adHostList = Get-ADComputer -Filter "Enabled -eq 'true'" | Select-Object -ExpandProperty Name 
        
        Write-Host "Successfully retrieved AD host info"
        WriteLog "Successfully retrieved AD host info"
    }
    catch {
        Write-Host $Error
        WriteLog $Error
        Write-Host "Failed to acquire Active host from Active Directory. Exiting script"
        WriteLog "Failed to acquire Active host from Active Directory. Exiting script"
        Exit
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
        Write-Host $Error
        WriteLog $Error
        Write-Host "An issue occurred when attempting to compare data sources. Exiting script"
        WriteLog "An issue occurred when attempting to compare data sources. Exiting script"
        Exit
    }
}
Function ExportResults{
# Export Results
Try {
    # Create the column heading line
    $columnHeading = "Hostname"
    
    # Export the column heading line followed by the unique rows to a new text file
    Write-Host "Exporting results to text file"
    WriteLog "Exporting results to text file"
    $columnHeading | Out-File -FilePath $outputPath -Encoding utf8
    $uniqueRows | Out-File -FilePath $outputPath -Append -Encoding utf8
    Write-Host "Hostnames in AD but not in CS have been exported to $outputPath."
    WriteLog "Hostnames in AD but not in CS have been exported to $outputPath."
    Write-Host "Exiting Script"
    WriteLog "Exiting Script"
    Exit
}
Catch {
    Write-Host $Error
    WriteLog $Error
    Write-Host "Export to text file failed."
    Write-Host "Exiting Script."
    WriteLog "Export to text file failed."
    WriteLog "Exiting Script."
    Exit
}
}
############################Do Stuff###############################

GetCSToken
RetrieveCSHosts
RetrieveADHosts
CompareResults
ExportResults
