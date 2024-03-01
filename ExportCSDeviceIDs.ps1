# Set your CrowdStrike API credentials
$client_id = '539f878ec7374bf3b4d6fa54b95697a1'
$client_secret = 'JPF7h2yWbvAtIl3U4Mn109VNmQ8zqwkrHK6E5gxX'

# Set your query filter
$filter = 'hostname:*'

# Set the CrowdStrike API endpoint
$url = 'https://api.crowdstrike.com/devices/queries/devices-scroll/v1'

# Set the CSV file name
$csv_file = 'c:\temp\device_ids.csv'

# Authenticate with the CrowdStrike API to obtain an access token
$auth_url = 'https://api.crowdstrike.com/oauth2/token'
$auth_data = @{
    'client_id' = $client_id
    'client_secret' = $client_secret
    'grant_type' = 'client_credentials'
}
$auth_response = Invoke-RestMethod -Uri $auth_url -Method Post -Body $auth_data
$access_token = $auth_response.access_token

# Set the query parameters
$params = @{
    'filter' = $filter
}

# Initialize list to hold hostnames
$hostnames = New-Object System.Collections.Generic.List[System.String]

# Set the cursor to $null for the initial request
$cursor = $null

# Make requests until all hosts are fetched
do {
    # Set the cursor in the request params
    if ($cursor) {
        $params['cursor'] = $cursor
    }

    # Make the request to the CrowdStrike API
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
        'Authorization' = "Bearer $access_token"
    }

    # Extract the hosts from the response
    $hosts = $response.resources

    # Add hostnames to the list
    foreach ($h in $hosts) {
        $hostnames.Add($h)
    }

    # Update the cursor for the next request
    $cursor = $response.meta.pagination.next
} while ($response.meta.pagination.next)

# Export hostnames to CSV file
if ($hostnames.Count -gt 0) {
    $hostnames > $csv_file
    Write-Host "Exported hosts to $csv_file"
} else {
    Write-Host "No hostnames found or retrieved. Export to CSV aborted."
}
