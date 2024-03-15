#This script retrieves firewall rule details from the CrowdStrike cloud.
#Written by Jim Roberts 03/15/2024

# Set the error action preference to stop on error
$ErrorActionPreference = "Stop"

# Import the PSFalcon module
Import-Module -Name PSFalcon

# Check if the directory C:\Temp exists and set a few variables
$Savepath = "C:\Temp"
if (!(Test-Path -Path $Savepath -PathType Container)) {
    New-Item -Path $Savepath -ItemType Directory
}

$LogName = "ADCSCompare_$((Get-Date).ToString("MMddyy HHmmss"))_.log"
$LogFile = Join-Path $Savepath $LogName
$OutputName = "FirewallRules_$((Get-Date).ToString("MMddyy HHmm"))_.csv"
$OutputFile = Join-Path $Savepath $OutputName

function WriteLog {
    Param ([string]$LogString)
    
    $TimeLog = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$TimeLog $LogString"
    Add-Content $LogFile -Value $LogMessage
}

WriteLog "Starting Script"

#$outputPath = "C:\temp\Delta_$((Get-Date).ToString("MMddyy HHmm"))_.csv"

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

function Export-FirewallRulesToCsv {
    Param (
        [string]$OutputFile
    )

    # Import the PSFalcon module
    Import-Module PSFalcon

    # Initialize variables for pagination
    $offset = 0
    $limit = 500  # Adjust the limit as needed based on API limits

    # Initialize an empty array to store all firewall rules
    $allFirewallRules = @()

    # Fetch firewall rules in batches until all records are retrieved
    do {
        try {
            # Fetch a batch of firewall rules with pagination
            $firewallRules = Get-FalconFirewallRule -Detailed -Offset $offset -Limit $limit
        } catch {
            Write-Error "Failed to retrieve firewall rules from CrowdStrike: $_"
            return
        }

        # Check if firewall rules were retrieved
        if (-not $firewallRules) {
            Write-Warning "No firewall rules found."
            return
        }

        # Add the batch of firewall rules to the array
        $allFirewallRules += $firewallRules

        # Increment the offset for the next batch
        $offset += $limit
    } while ($firewallRules.Count -eq $limit)

    # Export firewall rules to CSV file
    try {
        $allFirewallRules | Select-Object Name, Action, Protocol, Direction, Enabled, Source, Destination, Port, Description |
            Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "Firewall rules exported to $OutputFile"
    } catch {
        Write-Error "Failed to export firewall rules to CSV file: $_"
    }
}

# Call the function to acquire token
GetCSToken

# Call the function to export firewall rules to a CSV file
Export-FirewallRulesToCsv -OutputFile $OutputFile
