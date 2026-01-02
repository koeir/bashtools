#!/bin/bash

# Must be ran as root
if [ "$EUID" != 0 ]; then
    /bin/echo "[$0] Script must be ran as root."
    exit -1
fi

# Confirmation
read -p "[$0] Copy the executables to "/usr/bin"? (y/n): " confirm
if [[ ! $confirm =~ ^[yY]$ ]]; then
    /bin/echo "[$0] Cancelling..."
    exit 0
fi


bashtools="$(dirname "$0")"

# Check if tools directory exists
tools_dir="$bashtools/tools"
if [ ! -d "$tools_dir" ]; then 
    /bin/echo "[$0] Directory \"$bashtools/$tools_dir\" not found."
    exit -2
fi

# Find files in $tools_dir directory
# Stream full path of each file and increment with null char instead of newline
find "$tools_dir" -type f -print0 |

    # Read until null char and store in variable $tool
    while IFS= read -r -d '' tool; do
        # Get filename of tool,
        filename="$(/bin/echo "$tool" | awk -F '/' '{print $NF}')"

        # If it exists in /usr/bin already, copy the existing file to /tmp before overwriting
        if /bin/ls "/usr/bin" | grep -q "$filename"; then
            /bin/echo "[$0] ! Filename \"$filename\" found in "/usr/bin". !"
            /bin/echo "[$0] Making a copy of \"/usr/bin/$filename\" to /tmp."
            /bin/cp "/usr/bin/$filename" /tmp
        fi

        /bin/echo "[$0] Copying \"$tool\" to \"/usr/bin\"..."
        /bin/cp "$tool" "/usr/bin"
        
    done

exit 0
