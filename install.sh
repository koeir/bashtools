#!/bin/bash

# Colors lol
RED="\e[1;31m"
GREEN="\e[1;32m"
NORMAL="\e[0m"

if (( EUID != 0 )); then
    echo -e "${RED}[$0] Script must be ran as root.${NORMAL}"
    exit -1
fi

installation_dir="/usr/share/bashtools"
if [ ! -d "$installation_dir" ]; then
    echo "[$0] Making directory \"${installation_dir}\"..."
    mkdir -p "$installation_dir"

    export PATH="${PATH}:${installation_dir}"
fi

if [[ $1 != "-y" ]]; then
    read -p "[$0] Copy the executables to "${installation_dir}"? (y/n): " confirm
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

skipped=0
updated=0

# Find files in $tools_dir directory
# put them in the installation directory
# the tools are accessible via the interface "bashtools"
while IFS= read -r -d '' tool; do
    installed=false        
    filename="$(echo "$tool" | awk -F '/' '{print $NF}')"
   
    if [ -f "${installation_dir}/${filename}" ]; then
        
        if diff -q "$tool" "${installation_dir}/${filename}"; then

            installed=true
            skipped=$((skipped+1))

        else
            
            echo -e "${RED}[$0] ! Filename \"${filename}\" found in \"${installation_dir}\" !..."
            echo -e "...but the contents are different."
            echo -e "${GREEN}[$0] Making a copy of \"${installation_dir}/${filename}\" to /tmp...${NORMAL}"
            cp "${installation_dir}/${filename}" /tmp
            updated=$((updated+1))

        fi
    fi
    
    if [[ $installed == true ]]; then
        echo "[${0}] \"$filename\" already installed."
    else
        echo "[$0] Copying \"${tool}\" to \"${installation_dir}\"..."
        cp "$tool" "${installation_dir}/${filename}"
    fi
    
done < <(find "$tools_dir" -type f -executable -print0);

# Install the bashtools interface but in bin
installation_dir="/usr/bin"
bashtools_exec="$bashtools/bashtools"
tool="bashtools"
installed=false
if [ -f "$installation_dir/$tool" ]; then

    if diff -q "$bashtools_exec" "${installation_dir}/$tool"; then

        installed=true
        skipped=$((skipped+1))

    else
        
        echo -e "${RED}[$0] ! Filename \"$tool\" found in \"${installation_dir}\" !..."
        echo -e "...but the contents are different."
        echo -e "${GREEN}[$0] Making a copy of \"${installation_dir}/$tool\" to /tmp...${NORMAL}"
        cp "${installation_dir}/$tool" /tmp
        updated=$((updated+1))

    fi

fi

if [[ $installed == true ]]; then
    echo "[${0}] \"$tool\" already installed."
else
    echo "[$0] Copying \"$tool\" to \"${installation_dir}\"..."
    cp "$bashtools_exec" "${installation_dir}/$tool"
fi


echo
echo "[${0}] Done."
echo "[${0}] Overwritten files:    "${updated}""
echo "[${0}] Skipped files:        "${skipped}""

exit 0
