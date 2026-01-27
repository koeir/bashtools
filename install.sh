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

fi

echo ""
echo "[$0] NOTE:"
echo "[$0] Check if the tools are executable. Add permissions if they aren't"
echo ""

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

skipped=0
updated=0
installed=0
installtool() {
    if [ -z "$2" ]; then
        local installation_dir="${BASHTOOLS_INSTALLATION_DIR}"
    else
        local installation_dir="$2"
    fi

    local alreadyInstalled=false        
    local tool="$1"

    filename="$(echo "$tool" | awk -F '/' '{print $NF}')"

    if [ -f "${installation_dir}/${filename}" ]; then
        
        if diff -q "$tool" "${installation_dir}/${filename}"; then

            alreadyInstalled=true
            skipped=$((skipped+1))

        else
            
            echo -e "${RED}[$0] ! Filename \"${filename}\" found in \"${installation_dir}\" !..."
            echo -e "...but the contents are different."
            echo -e "${GREEN}[$0] Making a copy of \"${installation_dir}/${filename}\" to /tmp...${NORMAL}"
            cp "${installation_dir}/${filename}" /tmp
            updated=$((updated+1))

        fi
    fi
    
    if [[ $alreadyInstalled == true ]]; then
        echo "[$0] \"$filename\" already installed."
    else

        echo "[$0] Copying \"${tool}\" to \"${installation_dir}\"..."
        cp "$tool" "${installation_dir}/${filename}"
        installed=$((installed+1))

    fi
}

while IFS= read -r -d '' tool; do
    installtool "$tool"
done < <(find "$tools_dir" -type f -executable -print0);

bshtls="${bashtools}/bshtls"
installtool "$bshtls" "/usr/bin"

echo ""
echo "[$0] Done."
echo "[$0] Installed:            "${installed}""
echo "[$0] Overwritten files:    "${updated}""
echo "[$0] Skipped files:        "${skipped}""
echo ""
echo "[$0] TIP:"
echo "[$0] Append the installation directory to \$PATH (add it in your shell's startup file for persistence)."

exit 0
