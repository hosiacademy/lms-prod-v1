# PowerShell script to replace surfaceVariant with surfaceContainerHighest
# This fixes another set of deprecated_member_use warnings in Flutter

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$totalFiles = 0
$totalReplacements = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Replace .surfaceVariant with .surfaceContainerHighest
    $content = $content -replace '\.surfaceVariant\b', '.surfaceContainerHighest'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $replacements = ([regex]::Matches($originalContent, '\.surfaceVariant\b')).Count
        $totalReplacements += $replacements
        $totalFiles++
        Write-Host "Fixed $replacements instances in: $($file.FullName)"
    }
}

Write-Host "`nTotal: Fixed $totalReplacements instances across $totalFiles files"
