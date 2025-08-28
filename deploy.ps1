Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Deploy Jedi-LDBs addon to WoW AddOns folder
$ErrorActionPreference = 'Stop'

# Path to your WoW AddOns directory
$wowAddons = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"

# Source and destination
$src = Join-Path $PSScriptRoot 'src'
$dest = Join-Path $wowAddons 'Jedi-LDBs'

# Remove existing Jedi-LDBs folder if it exists
if (Test-Path $dest) {
	Write-Host "Removing existing $dest ..."
	Remove-Item $dest -Recurse -Force
}

# Copy all files from src to AddOns/Jedi-LDBs
Write-Host "Copying $src to $dest ..."
Copy-Item $src $dest -Recurse

Write-Host "Deployment complete."

