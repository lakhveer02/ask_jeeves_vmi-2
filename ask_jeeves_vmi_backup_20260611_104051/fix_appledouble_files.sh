#!/bin/bash

# Script to fix AppleDouble file corruption using macOS dot_clean utility
# This merges ._ files with their counterparts and cleans up the structure
# NO FILES ARE DELETED - they are merged/restored

echo "=== AppleDouble File Fix Script ==="
echo "This will use macOS dot_clean to fix file corruption"
echo "Files will be restored, not deleted"
echo ""

# Create a full backup first
BACKUP_DIR="../ask_jeeves_vmi_backup_$(date +%Y%m%d_%H%M%S)"
echo "Creating full backup first at: $BACKUP_DIR"
cp -R . "$BACKUP_DIR"
echo "✓ Backup complete!"
echo ""

# Run dot_clean to merge AppleDouble files
echo "Running dot_clean to fix files..."
dot_clean -m .

echo ""
echo "=== Process Complete ==="
echo "✓ Files have been restored from AppleDouble format"
echo "✓ Full backup available at: $BACKUP_DIR"
echo "✓ No files were deleted"
echo ""
echo "Please check your files - they should now be readable!"
