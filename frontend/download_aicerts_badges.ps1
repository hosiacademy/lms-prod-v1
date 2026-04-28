# Download AICERTS Certificate Badge SVGs
# This script downloads all AICERTS badge SVGs to avoid CORS issues on web platform

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "AICERTS Badge Downloader" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create badges directory
$badgesDir = "assets\images\courses\badges"
Write-Host "Creating directory: $badgesDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $badgesDir | Out-Null

# Change to badges directory
Set-Location $badgesDir

# List of all AICERTS badge SVGs
$badges = @(
    "AIC_AI-Quantum.svg",
    "AIC_AI-Researcher.svg",
    "AIC_AI-Ethical-Hacker.svg",
    "AIC_AI-Architect.svg",
    "AIC_AI-Robotics.svg",
    "AIC_BitcoinSecurity-1.svg",
    "AIC_AI-Data.svg",
    "AIC_AI-Legal.svg",
    "AIC_AI-Design.svg",
    "AIC_AI-Product-Manager-1.svg",
    "AIC_AI-Writer.svg",
    "AIC_AI-UX-Designer.svg",
    "AIC_AI-Learning-Development.svg",
    "AIC_AI-Finance.svg",
    "AIC_AI-Human-Resources.svg"
)

$baseUrl = "https://www.aicerts.ai/wp-content/uploads/2024/02"
$successCount = 0
$failCount = 0

Write-Host "Downloading $($badges.Count) badge SVGs..." -ForegroundColor Green
Write-Host ""

foreach ($badge in $badges) {
    $url = "$baseUrl/$badge"
    Write-Host "[$($successCount + $failCount + 1)/$($badges.Count)] Downloading: $badge..." -NoNewline

    try {
        Invoke-WebRequest -Uri $url -OutFile $badge -ErrorAction Stop
        Write-Host " ✓ Success" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " ✗ Failed" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Download Summary:" -ForegroundColor Cyan
Write-Host "  Success: $successCount" -ForegroundColor Green
Write-Host "  Failed:  $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "✓ Badges downloaded to: $(Get-Location)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Add 'assets/images/courses/badges/' to pubspec.yaml" -ForegroundColor White
    Write-Host "2. Run: flutter pub get" -ForegroundColor White
    Write-Host "3. Replace network badge loads with local assets" -ForegroundColor White
    Write-Host "4. Run: flutter clean && flutter run -d chrome" -ForegroundColor White
}

if ($failCount -gt 0) {
    Write-Host ""
    Write-Host "⚠ Some downloads failed. Check your internet connection and try again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
