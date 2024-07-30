#!/bin/bash

analyze_html_file() {
    local file=$1
    local prev_line=""
    # Read the file line by line
    while IFS= read -r line; do
        # Check if the current line contains the target pattern
        if echo "$line" | grep -q '<td class="tlaLBC">LBC</td>'; then
            # Check if the previous line contains the td element with a link
            if echo "$prev_line" | grep -q '<td class="[^"]*"><a href="[^"]*">[^<]*</a></td>'; then
                # Extract the link title from the previous line
                link_title=$(echo "$prev_line" | grep -oP '<a href="[^"]*">\K[^<]*(?=</a>)')
                # Print the link title
                echo "$(c++filt $link_title)"
            fi
        fi
        # Update the previous line
        prev_line="$line"
    done < "$file"
}

# Check if directory is given as argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Recursively find all HTML files in the given directory
find "$1" -type f -name "*.html" | while IFS= read -r file; do
    # Check if the file name ends with "func-c.html"
    if [[ "$file" == *func-c.html ]]; then
        # Analyze the HTML file
        # echo "Analyze $file"
        analyze_html_file "$file"
    fi
done

