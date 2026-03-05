$path = "service-account.json"
if (!(Test-Path $path)) {
    Write-Host "Error: 'service-account.json' file not found." -ForegroundColor Red
    exit
}

# Read content
$content = Get-Content -Raw $path
if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Host "Error: JSON file is empty." -ForegroundColor Red
    exit
}

# Minify JSON
try {
    $jsonObject = $content | ConvertFrom-Json
    $minifiedJson = $jsonObject | ConvertTo-Json -Compress -Depth 10
} catch {
    Write-Host "Error parsing JSON file: $_" -ForegroundColor Red
    exit
}

Write-Host "Writing clean .env file (No BOM)..." -ForegroundColor Cyan

# Prepare content
# Escape single quotes for the env file format
$jsonForEnv = $minifiedJson -replace "'", "''" 
$envContent = "SERVICE_ACCOUNT_JSON='$jsonForEnv'"
$envFile = ".env.temp.upload"

# Write using .NET to avoid PowerShell adding BOM (Byte Order Mark) which breaks Supabase CLI
try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText("$PWD/$envFile", $envContent, $utf8NoBom)
} catch {
    Write-Host "Error writing env file: $_" -ForegroundColor Red
    exit
}

# Set secret via file
supabase secrets set --env-file $envFile --project-ref zgdzmkyphimaznebmgrl

# Cleanup
if (Test-Path $envFile) {
    Remove-Item $envFile
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Success! Secret updated." -ForegroundColor Green
    Write-Host "Please Restart App & Test." -ForegroundColor Green
} else {
    Write-Host "❌ Failed to set secret." -ForegroundColor Red
}
