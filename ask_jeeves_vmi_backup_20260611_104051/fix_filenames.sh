#!/bin/bash

# Script to fix file names by removing ._ prefix (macOS metadata files)
# This renames files without deleting them

echo "Starting file rename process..."
echo "This will rename files starting with '._' to remove that prefix"
echo ""

# Counter for tracking
count=0

# Find all files starting with ._ and rename them
find . -name "._*" -type f | while read file; do
    # Get directory and filename
    dir=$(dirname "$file")
    filename=$(basename "$file")
    
    # Remove the ._ prefix
    newname="${filename#._}"
    
    # Skip if the target file already exists
    if [ -f "$dir/$newname" ]; then
        echo "Skipping: $file (target already exists)"
    else
        # Rename the file
        mv "$file" "$dir/$newname"
        echo "Renamed: $file -> $dir/$newname"
        ((count++))
    fi
done

echo ""
echo "Process complete! Renamed $count files."
echo "No files were deleted - only renamed."
