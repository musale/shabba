#!/bin/bash

# Check if downloads.txt exists
if [ ! -f "downloads.txt" ]; then
    echo "Error: downloads.txt file not found!"
    exit 1
fi

# Read downloads.txt line by line and run dm4a for each line
while IFS= read -r line; do
    # Skip empty lines
    if [ -n "$line" ]; then
        echo "Processing: $line"
        dm4a "$line"
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "✓ Successfully processed: $line"
        else
            echo "✗ Failed to process: $line"
        fi
        echo "---"
    fi
done < downloads.txt

echo "Finished processing all downloads."