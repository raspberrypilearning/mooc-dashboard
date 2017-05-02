#!/bin/bash
dir=$1
OUTPUT="$(find $dir -type f -name "*.csv" | wc -l)"
echo "Number of files: $OUTPUT" 
find $dir -type f -name "*.csv" -print0 | xargs -0 perl -i.bak -pe 's/\x0D\x0A/\x20/g'
echo "Deleting ..."
find $dir -name "*.bak" -print0 | xargs -0 rm
