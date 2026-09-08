# Build the image and run the app at http://localhost:8000
$ErrorActionPreference = "Stop"

Set-Location (Split-Path -Parent $PSScriptRoot)

docker build -t pm-app .
if ($LASTEXITCODE -ne 0) { throw "docker build failed" }

# Query first: "docker rm" on a missing container writes to stderr, which
# PowerShell turns into a terminating error under ErrorActionPreference Stop.
if (docker ps -aq -f 'name=^pm-app$') { docker rm -f pm-app | Out-Null }

$runArgs = @("run", "-d", "--name", "pm-app", "-p", "8000:8000", "-v", "pm-data:/app/data")
if (Test-Path ".env") { $runArgs += @("--env-file", ".env") }
$runArgs += "pm-app"

docker @runArgs | Out-Null
if ($LASTEXITCODE -ne 0) { throw "docker run failed" }

# The container is up before uvicorn is listening, so wait for a real response
# rather than claiming the app is ready when it is not.
Write-Host -NoNewline "Starting"
for ($i = 0; $i -lt 60; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:8000/api/health" -UseBasicParsing -TimeoutSec 2 | Out-Null
        Write-Host "`nRunning at http://localhost:8000"
        exit 0
    } catch {
        Write-Host -NoNewline "."
        Start-Sleep -Milliseconds 500
    }
}

Write-Host "`nServer did not respond in time. Check: docker logs pm-app"
exit 1
