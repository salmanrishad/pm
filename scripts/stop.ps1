# Stop and remove the app container. The pm-data volume is left intact.
if (docker ps -aq -f 'name=^pm-app$') {
    docker rm -f pm-app | Out-Null
    Write-Host "Stopped."
} else {
    Write-Host "Not running."
}
