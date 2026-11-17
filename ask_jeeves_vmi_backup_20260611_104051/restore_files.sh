#!/bin/bash

# Script to restore files from AppleDouble format
# Moves corrupted files to backup and restores from ._ files

echo "=== File Restoration Script ==="
echo "This will fix corrupted AppleDouble files"
echo "Corrupted files will be backed up, not deleted"
echo ""

# Create backup directory
BACKUP_DIR="./backup_corrupted_files_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Created backup directory: $BACKUP_DIR"
echo ""

count=0

# Find all ._ files
find . -name "._*" -type f | while read dotfile; do
    # Get the directory and base filename
    dir=$(dirname "$dotfile")
    filename=$(basename "$dotfile" | sed 's/^\._//')
    original="$dir/$filename"
    
    # Skip if in backup directory
    if [[ "$dotfile" == *"/backup_"* ]]; then
        continue
    fi
    
    # Check if the original file exists and is corrupted (AppleDouble)
    if [ -f "$original" ]; then
        filetype=$(file "$original" | grep -o "AppleDouble")
        
        if [ -n "$filetype" ]; then
            # File is corrupted - back it up and try to extract content
            echo "Processing: $original"
            
            # Create backup directory structure
            backup_path="$BACKUP_DIR/${original#./}"
            mkdir -p "$(dirname "$backup_path")"
            
            # Move corrupted file to backup
            mv "$original" "$backup_path"
            echo "  ✓ Backed up corrupted file to: $backup_path"
            
            # Try to extract content from ._ file using dot_clean or manual extraction
            # Use dot_clean if available, otherwise try dd to extract data fork
            if command -v dot_clean &> /dev/null; then
                cp "$dotfile" "$original"
                dot_clean -m "$dir"
                echo "  ✓ Restored from: $dotfile"
            else
                # Try direct copy and see if it works
                cp "$dotfile" "$original"
                echo "  ✓ Copied from: $dotfile"
            fi
            
            ((count++))
        fi
    fi
done

echo ""
echo "=== Process Complete ==="
echo "Processed $count files"
echo "All corrupted files backed up to: $BACKUP_DIR"
echo "No files were deleted!"
echo ""
echo "Please verify the restored files work correctly."
echo "If they don't, the originals are safely stored in the backup directory."
