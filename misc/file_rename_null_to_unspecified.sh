#!/bin/bash

# Loop through all files in the current directory
for file in *; do
  # Check if the file name contains 'null_bframes'
  if [[ "$file" == *null_bframes* ]]; then
    # Replace 'null' with 'unspecified' and rename the file
    new_name="${file//null/unspecified}"
    mv "$file" "$new_name"
    echo "Renamed: $file -> $new_name"
  fi
done
