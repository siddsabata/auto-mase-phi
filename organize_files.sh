#!/bin/bash

# Enable extended glob patterns
shopt -s extglob

# Iterate over all subdirectories in the current directory
for dir in */; do
    # Check if it is a directory
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        
        # Create a "mafs" directory inside the subdirectory
        mkdir -p "${dir}mafs"
        
        # Move all files (not directories) from the subdirectory to the "mafs" directory
        for file in "${dir}"*; do
            if [ -f "$file" ] && [ "$(basename "$file")" != "mafs" ]; then
                echo "Moving $file to ${dir}mafs/"
                mv "$file" "${dir}mafs/"
            fi
        done
    fi
done

