#!/bin/bash

# Script to download AICerts course images and convert SVGs to PNGs
# This avoids CORS issues when running Flutter web app

set -e  # Exit on error

echo "================================================"
echo "Downloading AICerts Course Images"
echo "================================================"
echo ""

# Create directories if they don't exist
mkdir -p assets/images/courses
mkdir -p assets/data

# Check if imagemagick is installed (for SVG to PNG conversion)
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagick not found. Installing..."
    echo "   Please install ImageMagick:"
    echo "   - Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "   - macOS: brew install imagemagick"
    echo "   - Windows: Download from https://imagemagick.org/script/download.php"
    echo ""
    read -p "Press Enter after installing ImageMagick to continue..."
fi

# Array of course images to download
declare -a COURSES=(
    "ai-context-engineering|https://www.aicerts.ai/wp-content/uploads/2025/11/AIC_AI-Context-Engineering.svg"
    "ai-pharma|https://www.aicerts.ai/wp-content/uploads/2025/11/AIC_AI-Pharma-1.svg"
    "rsaif-playbook|https://www.aicerts.ai/wp-content/uploads/2025/10/AIC_Practitioners-Playbook-for-RSAIF.svg"
    "ai-marketing|https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-AI-Marketing.svg"
    "blockchain-fundamentals|https://www.aicerts.ai/wp-content/uploads/2024/01/blockchain-fundamentals-badge.svg"
    "ai-executive-leadership|https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-Executive-Leadership.svg"
    "ethical-hacker|https://www.aicerts.ai/wp-content/uploads/2024/01/ethical-hacker-badge.svg"
    "ai-product-management|https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-AI-Product-Management.svg"
    "data-science|https://www.aicerts.ai/wp-content/uploads/2024/01/data-science-badge.svg"
    "ai-sales|https://www.aicerts.ai/wp-content/uploads/2024/08/AIC-AI-Sales.svg"
)

# Download and convert each image
for course in "${COURSES[@]}"; do
    IFS='|' read -r name url <<< "$course"

    echo "📥 Downloading: $name"
    echo "   URL: $url"

    # Download SVG
    svg_path="assets/images/courses/${name}.svg"
    png_path="assets/images/courses/${name}.png"

    if curl -sSL -f "$url" -o "$svg_path"; then
        echo "   ✓ Downloaded SVG"

        # Convert SVG to PNG
        if command -v convert &> /dev/null; then
            if convert -background white -flatten "$svg_path" "$png_path"; then
                echo "   ✓ Converted to PNG"
            else
                echo "   ⚠️  PNG conversion failed"
            fi
        else
            echo "   ⚠️  Skipping PNG conversion (ImageMagick not installed)"
        fi
    else
        echo "   ❌ Download failed"
    fi

    echo ""
done

echo "================================================"
echo "✅ Download Complete!"
echo "================================================"
echo ""
echo "Images saved to: assets/images/courses/"
echo ""
echo "Next steps:"
echo "1. Run 'flutter pub get' to update assets"
echo "2. Run your app with 'flutter run -d chrome'"
echo "3. Images will now load from local assets (no CORS issues!)"
echo ""
