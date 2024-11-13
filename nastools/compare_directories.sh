#!/bin/bash

# Function to print usage information
function usage {
    echo "Usage: $0 dir1 dir2"
    echo "  dir1 and dir2 are the directories to compare"
}

# Check if two arguments are passed
if [ $# -ne 2 ]; then
    usage
    exit 1
fi

# Check if both directories exist
if [ ! -d "$1" ]; then
    echo "Directory '$1' does not exist"
    usage
    exit 1
fi

if [ ! -d "$2" ]; then
    echo "Directory '$2' does not exist"
    usage
    exit 1
fi

# Compare the directories and output files that are not in both
diff <(cd "$1" && find . -type f | sort) <(cd "$2" && find . -type f | sort) | grep -E '^<|^>' | sed 's/^< //;s/^> //' | sort -u
