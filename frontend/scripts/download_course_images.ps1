# PowerShell Script to download AICerts course images
# This avoids CORS issues when running Flutter web app

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Downloading AICerts Course Images" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path "assets/images/courses" | Out-Null
New-Item -ItemType Directory -Force -Path "assets/data" | Out-Null

# Array of course images to download
$courses = @(
    @{name="ai-context-engineering"; url="https://www.aicerts.ai/wp-content/uploads/2025/11/AIC_AI-Context-Engineering.svg"},
    @{name="ai-pharma"; url="https://www.aicerts.ai/wp-content/uploads/2025/11/AIC_AI-Pharma-1.svg"},
    @{name="rsaif-playbook"; url="https://www.aicerts.ai/wp-content/uploads/2025/10/AIC_Practitioners-Playbook-for-RSAIF.svg"},
    @{name="ai-marketing"; url="https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-AI-Marketing.svg"},
    @{name="blockchain-fundamentals"; url="https://www.aicerts.ai/wp-content/uploads/2024/01/blockchain-fundamentals-badge.svg"},
    @{name="ai-executive-leadership"; url="https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-Executive-Leadership.svg"},
    @{name="ethical-hacker"; url="https://www.aicerts.ai/wp-content/uploads/2024/01/ethical-hacker-badge.svg"},
    @{name="ai-product-management"; url="https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-AI-Product-Management.svg"},
    @{name="data-science"; url="https://www.aicerts.ai/wp-content/uploads/2024/01/data-science-badge.svg"},
    @{name="ai-sales"; url="https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-AI-Sales.svg"}
)

# Download each image
foreach ($course in $courses) {
    $name = $course.name
    $url = $course.url
    $svgPath = "assets/images/courses/$name.svg"

    Write-Host "📥 Downloading: $name" -ForegroundColor Yellow
    Write-Host "   URL: $url"

    try {
        Invoke-WebRequest -Uri $url -OutFile $svgPath -ErrorAction Stop
        Write-Host "   ✓ Downloaded SVG" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Download failed: $_" -ForegroundColor Red
    }

    Write-Host ""
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ Download Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images saved to: assets/images/courses/"
Write-Host ""
Write-Host "📝 Note: SVG to PNG conversion requires additional tools" -ForegroundColor Yellow
Write-Host "   You can use online converters or install Inkscape/ImageMagick"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. (Optional) Convert SVGs to PNGs for better compatibility"
Write-Host "2. Run 'flutter pub get' to update assets"
Write-Host "3. Run your app with 'flutter run -d chrome'"
Write-Host "4. Images will now load from local assets (no CORS issues!)"
Write-Host ""
