$baseUri = "" #https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod
$apiKey = ""
$headers = @{
    "x-api-key" = $apiKey
    "Content-Type" = "application/json"
}

# Function to make API calls
function Test-ApiEndpoint {
    param ($Uri, $Method, $Body)
    try {
        if ($Method -eq "Get") {
            $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
        } else {
            $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -Body $Body
        }
        Write-Output "Success: $response"
    } catch {
        Write-Output "Error: $($_.Exception.Message)"
        Write-Output "Response: $($_.ErrorDetails.Message)"
    }
}

# Test 1: GET /tokens/count
Write-Output "Testing GET /tokens/count"
Test-ApiEndpoint -Uri "$baseUri/tokens/count?id=my-token" -Method Get

# Test 2: POST /tokens/count (set)
Write-Output "Testing POST /tokens/count (set)"
$body = @{ id = "my-token"; action = "set"; count = 100 } | ConvertTo-Json
Test-ApiEndpoint -Uri "$baseUri/tokens/count" -Method Post -Body $body

# Test 3: POST /tokens/count (subtract)
Write-Output "Testing POST /tokens/count (subtract)"
$body = @{ id = "my-token"; action = "subtract" } | ConvertTo-Json
Test-ApiEndpoint -Uri "$baseUri/tokens/count" -Method Post -Body $body

# Test 4: GET /tokens/count (verify)
Write-Output "Testing GET /tokens/count (verify)"
Test-ApiEndpoint -Uri "$baseUri/tokens/count?id=my-token" -Method Get

# Test 5: POST /ec2 (start)
Write-Output "Testing POST /ec2 (start)"
$body = @{ action = "start" } | ConvertTo-Json
Test-ApiEndpoint -Uri "$baseUri/ec2" -Method Post -Body $body
Start-Sleep -Seconds 10  # Wait for EC2 state change

# Test 6: GET /ec2/state
Write-Output "Testing GET /ec2/state"
Test-ApiEndpoint -Uri "$baseUri/ec2/state" -Method Get

# Test 7: POST /ec2 (stop)
Write-Output "Testing POST /ec2 (stop)"
$body = @{ action = "stop" } | ConvertTo-Json
Test-ApiEndpoint -Uri "$baseUri/ec2" -Method Post -Body $body
Start-Sleep -Seconds 10  # Wait for EC2 state change

# Test 8: GET /ec2/state (verify)
Write-Output "Testing GET /ec2/state (verify)"
Test-ApiEndpoint -Uri "$baseUri/ec2/state" -Method Get