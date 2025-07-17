$apiEndpoint = "https://XXXXXX.execute-api.us-east-1.amazonaws.com/prod/ec2"
$state_endpoint = "https://XXXXXX.execute-api.us-east-1.amazonaws.com/prod/ec2/state"
$apiKey = "XXXXXXXXXXXXXXXXXX"

# Stop instance
$body = @{ action = "stop" } | ConvertTo-Json
Invoke-RestMethod -Uri $apiEndpoint -Method Post -Headers @{ "x-api-key" = $apiKey } -Body $body -ContentType "application/json"

# Start instance
$body = @{ action = "start" } | ConvertTo-Json
Invoke-RestMethod -Uri $apiEndpoint -Method Post -Headers @{ "x-api-key" = $apiKey } -Body $body -ContentType "application/json"

# Get State
Invoke-RestMethod -Uri $state_Endpoint -Method Get -Headers @{ "x-api-key" = $apiKey } -ContentType "application/json"
