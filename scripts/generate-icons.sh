#!/bin/bash
# Simple icon generator for voxtype
# Requires ImageMagick: sudo apt install imagemagick

set -e

ICON_DIR="src-tauri/icons"
COLOR="#6366f1"  # Indigo
TEXT_COLOR="white"

mkdir -p "$ICON_DIR"

echo "Generating icons..."

# PNG icons
for size in 32 128 256 512; do
    echo "Creating ${size}x${size}.png..."
    convert -size ${size}x${size} \
        xc:"$COLOR" \
        -fill "$TEXT_COLOR" \
        -font "DejaVu-Sans-Bold" \
        -pointsize $((size / 2)) \
        -gravity center \
        -annotate +0+0 "V" \
        "$ICON_DIR/${size}x${size}.png"
done

# 2x version
echo "Creating 128x128@2x.png..."
convert -size 256x256 \
    xc:"$COLOR" \
    -fill "$TEXT_COLOR" \
    -font "DejaVu-Sans-Bold" \
    -pointsize 128 \
    -gravity center \
    -annotate +0+0 "V" \
    "$ICON_DIR/128x128@2x.png"

# macOS icon
echo "Creating icon.icns..."
mkdir -p "$ICON_DIR/icon.iconset"
for size in 16 32 64 128 256 512; do
    convert "$ICON_DIR/512x512.png" -resize ${size}x${size} "$ICON_DIR/icon.iconset/icon_${size}x${size}.png"
    if [ $size -le 256 ]; then
        convert "$ICON_DIR/512x512.png" -resize $((size*2))x$((size*2)) "$ICON_DIR/icon.iconset/icon_${size}x${size}@2x.png"
    fi
done
iconutil -c icns "$ICON_DIR/icon.iconset" -o "$ICON_DIR/icon.icns" 2>/dev/null || echo "iconutil not available (macOS only)"
rm -rf "$ICON_DIR/icon.iconset"

# Windows icon
echo "Creating icon.ico..."
convert "$ICON_DIR/256x256.png" "$ICON_DIR/128x128.png" "$ICON_DIR/32x32.png" "$ICON_DIR/icon.ico" 2>/dev/null || echo "Failed to create .ico (non-critical)"

echo "✓ Icons generated successfully!"

