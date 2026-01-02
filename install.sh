#!/bin/bash

# Colors lol
RED="\e[1;31m"
GREEN="\e[1;32m"
NORMAL="\e[0m"

# Must be ran as root
if [ "$EUID" != 0 ]; then
    /bin/echo -e "${RED}[$0] Script must be ran as root.${NORMAL}"
    exit -1
fi

# Confirmation
read -p "[$0] Copy the executables to "/usr/bin"? (y/n): " confirm
if [[ ! $confirm =~ ^[yY]$ ]]; then
    /bin/echo -e "[$0] Cancelling..."
    exit 0
fi


bashtools="$(dirname "$0")"

# Check if tools directory exists
tools_dir="${bashtools}/tools"
if [ ! -d "$tools_dir" ]; then 
    /bin/echo -e "${RED}[$0] Directory \"${bashtools}/${tools_dir}\" not found.${NORMAL}"
    exit -2
fi

# Check if hashcmp tool exists; needed for later
if [ ! -f "$tools_dir/hashcmp" ]; then
    /bin/echo -e "${RED}[${0}]"${tools}/hashcmp" not found.${NORMAL}"
    exit -3
fi

skipped=0
updated=0

# Find files in $tools_dir directory
# Stream full path of each file and increment with null char instead of newline
# Read until null char and store in variable $tool
while IFS= read -r -d '' tool; do
    installed="false"        

    # Get filename of tool,
    filename="$(/bin/echo "$tool" | awk -F '/' '{print $NF}')"
   
    # If it exists in /usr/bin already, 
    if /bin/ls "/usr/bin" | grep -q "$filename"; then
        
        # Compare the hashes of the two files
        if ! "${tools_dir}"/hashcmp "$tool" /usr/bin/${filename} &> /dev/null; then
            
            # If the hashes are different, copy the /usr/bin/file to /tmp before overwriting
            /bin/echo -e "${RED}[$0] ! Filename \"${filename}\" found in "/usr/bin". !${NORMAL}"
            /bin/echo -e "${GREEN}[$0] Making a copy of \"/usr/bin/${filename}\" to /tmp...${NORMAL}"
            /bin/cp "/usr/bin/${filename}" /tmp
            updated=$((updated+1))
        else
            installed="true"
            skipped=$((skipped+1))
        fi
    fi
    
    # If it's already installed, skip
    if [[ "$installed" != "true" ]]; then
        /bin/echo "[$0] Copying \"${tool}\" to \"/usr/bin\"..."
        /bin/cp "$tool" "/usr/bin"
    else
        /bin/echo "[${0}] "$tool" already installed."
    fi
    
done < <(find "$tools_dir" -type f -print0);

/bin/echo
/bin/echo "[${0}] Done."
/bin/echo "[${0}] Overwritten files:    "${updated}""
/bin/echo "[${0}] Skipped files:        "${skipped}""

exit 0
