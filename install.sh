#!/bin/bash

# Colors lol 
RED="\e[1;31m"
GREEN="\e[1;32m"
NORMAL="\e[0m"

if (( EUID != 0 )); then
    echo -e "[$0] Script must be ran as root.${NORMAL}"
    exit -1
fi

force=false
replace=false
for ((i = 1; i <= $#; i++)); do
    if [[ "${!i}" == "-h" ]] || [[ "${!i}" == "--help" ]]; then
        echo "Usage: ./install.sh [OPTIONS]"
        echo ""
        echo "OPTIONS:"
        echo "-h, --help                display this prompt and exit"
        echo "-y                        skip confirmation prompt"
        echo "-[0-2]                    pre-pick choices"
        echo "--exclude=<x>,<y>,<z>     exclude specified tools"
        echo "--replace                 replace existing files"

        exit 0
    fi

    if [[ "${!i}" == "-y" ]]; then
        force=true
        continue
    fi

    if [[ "${!i}" =~ ^--exclude= ]]; then
        IFS=',' read -r -a exclude <<< "${!i#*=}"

        echo -n "[$0] excluding: "
        for thing in "${exclude[@]}"; do
            echo -n "$thing "
        done
        echo ""

        continue
    fi

    if [[ "${!i}" == "--replace" ]]; then
        replace=true
        continue
    fi

    if [[ "${!i}" =~ ^-[0-2]$ ]]; then
        choice="${!i#*-}"
        continue
    fi

    echo "$0: "${!i}": unknown parameter"
    exit 1
done

if [ ! -v "choice" ]; then
    echo "Where to install?"
    echo "0: /usr/share/bashtools [default]"
    echo "1: /usr/bin"
    echo "2: other"

    while true; do
        read -r choice
        choice=${choice:-0}

        [[ "$choice" =~ ^[0-2]$ ]] && break

        echo ""
        echo "[$0] Invalid choice"
    done
fi

BASHTOOLS_INSTALLATION_DIR="/usr/share/bashtools"
case "$choice" in
    1)
        BASHTOOLS_INSTALLATION_DIR="/usr/bin"
        ;;
    2)
        read -p "where?: " choice
        BASHTOOLS_INSTALLATION_DIR="$choice"
        ;;
esac


if ! $force; then
    read -p "[$0] Copy the executables to "${BASHTOOLS_INSTALLATION_DIR}"? (y/n): " confirm
    if [[ ! $confirm =~ ^[yY]$ ]]; then
        echo -e "[$0] Cancelling..."
        exit 0
    fi
fi

if [ ! -d "$BASHTOOLS_INSTALLATION_DIR" ]; then
    echo "[$0] Making directory \`${BASHTOOLS_INSTALLATION_DIR}\`..."
    if ! mkdir -p "$BASHTOOLS_INSTALLATION_DIR"; then
        echo "[$0] Failed to make directory"
        exit 1
    fi
fi

bashtools="$(dirname "$0")"
tools_dir="${bashtools}/tools"
if [ ! -d "$tools_dir" ]; then
    echo -e "[$0] Directory \`${tools_dir}\` not found.${NORMAL}"
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

    if [ -e "$installation_dir/$filename" ]; then

        if diff -q "$tool" "$installation_dir/$filename" &> /dev/null; then
            alreadyInstalled=true
            skipped=$((skipped+1))
        else
            echo -e "[$0] found in \`$installation_dir\` but the contents are different: $filename"

            ! $replace && return

            randnum=$RANDOM
            echo -e "[$0] ${GREEN}$installation_dir/$filename -> /tmp/$filename-$randnum${NORMAL}"
            mv "$installation_dir/$filename" "/tmp/$filename-$randnum"
            updated=$((updated+1))
        fi
    fi

    if $alreadyInstalled; then
        echo "[$0] already installed: $filename"
    else
        echo "[$0] installing: $tool"
        install -m 755 "$tool" "$installation_dir/$filename"
        installed=$((installed+1))
    fi
}

echo "[$0] installing tools to \`$BASHTOOLS_INSTALLATION_DIR\`"
while IFS= read -r -d '' tool; do
    doExclude=false

    tool_basename="$(basename "$tool")"
    for thing in "${exclude[@]}"; do
        [ "$tool_basename" == "$thing" ] &&
            doExclude=true &&
            echo "[$0] skipping: $tool_basename"
    done

    ! $doExclude && installtool "$tool"
done < <(find "$tools_dir" -type f -executable -print0);

bshtls="${bashtools}/bshtls"
installtool "$bshtls" "/usr/bin"

echo ""
echo "[$0] Done."
echo "[$0] Installed:            "${installed}""
echo "[$0] Overwritten files:    "${updated}""
echo "[$0] Skipped files:        "${skipped}""
exit 0
