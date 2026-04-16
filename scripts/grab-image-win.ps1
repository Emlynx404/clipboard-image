# Windows clipboard image extraction
# Usage: grab-image-win.ps1 [save_directory]
# Output: JSON to stdout

param(
    [string]$SaveDir = $env:TEMP
)

Add-Type -AssemblyName System.Windows.Forms

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$rand = -join ((0..3) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
$filename = "claude-paste-$timestamp-$rand.png"
$filepath = Join-Path $SaveDir $filename

# Check clipboard for image
$image = [System.Windows.Forms.Clipboard]::GetImage()

if ($null -eq $image) {
    Write-Output '{"success":false,"error":"No image found in clipboard"}'
    exit 1
}

# Ensure save directory exists
if (-not (Test-Path $SaveDir)) {
    New-Item -ItemType Directory -Path $SaveDir -Force | Out-Null
}

# Save as PNG
try {
    $image.Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)
} catch {
    Write-Output '{"success":false,"error":"Failed to export clipboard image"}'
    exit 1
}

# Resize if wider than 1920px (requires ImageMagick)
if ((Get-Command "convert" -ErrorAction SilentlyContinue) -and $image.Width -gt 1920) {
    & convert $filepath -resize 1920x $filepath 2>$null
}

$image.Dispose()

$filepath = $filepath -replace '\\', '/'
Write-Output "{`"success`":true,`"path`":`"$filepath`"}"
