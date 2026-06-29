$token = "YOUR_OAUTH_TOKEN_HERE"
$bucket = "mending-gabung.firebasestorage.app"
$url = "https://storage.googleapis.com/storage/v1/b/$bucket"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    cors = @(
        @{
            origin = @("*")
            method = @("GET", "OPTIONS")
            maxAgeSeconds = 3600
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body $body
    Write-Output "CORS set successfully for $bucket"
} catch {
    Write-Error "Failed to set CORS: $_"
    Write-Error $_.Exception.Response.Content.ReadAsStringAsync().Result
}
