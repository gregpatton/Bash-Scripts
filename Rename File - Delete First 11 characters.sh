#!/bin/bash

# Replace "/path/to/directory" with the actual path to your directory
#directory="/path/to/directory"

# Move to the target directory
#cd "$directory" || exit

# Loop through each file in the directory
for file in *; do
    # Check if the file is a regular file (not a directory or a special file)
    if [[ -f "$file" ]]; then
        # Get the new file name by removing the first 11 characters
        new_name="${file:11}"

        # Check if the new name is not empty (i.e., the original filename had at least 11 characters)
        if [[ -n "$new_name" ]]; then
            # Rename the file
            mv "$file" "$new_name"
            echo "Renamed: $file -> $new_name"
        else
            echo "Skipping: $file (Name length < 11)"
        fi
    fi
done
