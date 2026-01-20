#!/bin/bash

# Colors lol
RED="\e[1;31m"
GREEN="\e[1;32m"
NORMAL="\e[0m"

if (( EUID != 0 )); then

    echo -e "${RED}[$0] Script must be ran as root.${NORMAL}"
    exit -1

fi

# Do not change for the love of god
BASHTOOLS_INSTALLATION_DIR="/usr/share/bashtools"
if [ ! -d "$BASHTOOLS_INSTALLATION_DIR" ]; then

    echo "[$0] Making directory \"${BASHTOOLS_INSTALLATION_DIR}\"..."
    mkdir -p "$BASHTOOLS_INSTALLATION_DIR"

    export PATH="${PATH}:${BASHTOOLS_INSTALLATION_DIR}"

fi

if [[ $1 != "-y" ]]; then

    read -p "[$0] Copy the executables to "${BASHTOOLS_INSTALLATION_DIR}"? (y/n): " confirm
    if [[ ! $confirm =~ ^[yY]$ ]]; then
        echo -e "[$0] Cancelling..."
        exit 0
    fi

fi


bashtools="$(dirname "$0")"
tools_dir="${bashtools}/tools"
if [ ! -d "$tools_dir" ]; then 

    echo -e "${RED}[$0] Directory \"${tools_dir}\" not found.${NORMAL}"
    exit -2

fi
chmod +x -R "$tools_dir"

skipped=0
updated=0

# Find files in $tools_dir directory
# put them in the installation directory
# the tools are accessible via the interface "bashtools"
while IFS= read -r -d '' tool; do

    installed=false        
    filename="$(echo "$tool" | awk -F '/' '{print $NF}')"
   
    if [ -f "${BASHTOOLS_INSTALLATION_DIR}/${filename}" ]; then
        
        if diff -q "$tool" "${BASHTOOLS_INSTALLATION_DIR}/${filename}"; then

            installed=true
            skipped=$((skipped+1))

        else
            
            echo -e "${RED}[$0] ! Filename \"${filename}\" found in \"${BASHTOOLS_INSTALLATION_DIR}\" !..."
            echo -e "...but the contents are different."
            echo -e "${GREEN}[$0] Making a copy of \"${BASHTOOLS_INSTALLATION_DIR}/${filename}\" to /tmp...${NORMAL}"
            cp "${BASHTOOLS_INSTALLATION_DIR}/${filename}" /tmp
            updated=$((updated+1))

        fi
    fi
    
    if [[ $installed == true ]]; then
        echo "[${0}] \"$filename\" already installed."
    else

        echo "[$0] Copying \"${tool}\" to \"${BASHTOOLS_INSTALLATION_DIR}\"..."
        cp "$tool" "${BASHTOOLS_INSTALLATION_DIR}/${filename}"

    fi
    
done < <(find "$tools_dir" -type f -executable -print0);

echo ""
echo "[${0}] Done."
echo "[${0}] Overwritten files:    "${updated}""
echo "[${0}] Skipped files:        "${skipped}""

exit 0
