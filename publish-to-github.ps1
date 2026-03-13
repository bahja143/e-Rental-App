# Publish Hantario Rental to GitHub
# Run this script AFTER completing gh auth login (if prompted)

$ErrorActionPreference = "Stop"
$gh = "$env:ProgramFiles\GitHub CLI\gh.exe"

if (-not (Test-Path $gh)) {
    Write-Host "GitHub CLI not found. Install from: https://cli.github.com/" -ForegroundColor Red
    exit 1
}

# Check if authenticated
$authStatus = & $gh auth status 2>&1
if ($authStatus -match "You are not logged in") {
    Write-Host "Please authenticate first. Run:" -ForegroundColor Yellow
    Write-Host "  & '$gh' auth login" -ForegroundColor Cyan
    Write-Host "Then run this script again." -ForegroundColor Yellow
    exit 1
}

# Create repo and push
Write-Host "Creating GitHub repository and pushing code..." -ForegroundColor Green
Set-Location $PSScriptRoot

& $gh repo create e-Rental-App --public --source . --remote origin --push

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDone! Your repo is live at: https://github.com/$(& $gh api user -q .login)/e-Rental-App" -ForegroundColor Green
} else {
    if ($LASTEXITCODE -eq 4) {
        Write-Host "`nRepo 'e-Rental-App' may already exist. Adding remote and pushing..." -ForegroundColor Yellow
        git remote add origin "https://github.com/$(& $gh api user -q .login)/e-Rental-App.git" 2>$null
        git branch -M main 2>$null
        git push -u origin main
    }
}
