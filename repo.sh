#!/bin/bash

# Repo management script

REPO_DIR="repo"
PACKAGE_DIR="$REPO_DIR/packages"
PACKAGES_FILE="$REPO_DIR/packages.txt"

# Function to create the repo directory if it does not exist
function setup_repo {
    if [ ! -d "$REPO_DIR" ]; then
        echo "Creating repo directory: $REPO_DIR"
        mkdir -p "$PACKAGE_DIR"
    else
        echo "Using existing repo directory: $REPO_DIR"
    fi

    # Create packages.txt if it does not exist
    if [ ! -f "$PACKAGES_FILE" ]; then
        echo "Creating packages.txt file."
        touch "$PACKAGES_FILE"
    fi
}

# Function to fetch and add multiple packages to the repo
function add_packages {
    local packages=("$@")

    if [ "${#packages[@]}" -eq 0 ]; then
        echo "No packages specified to add."
        exit 1
    fi

    for package_name in "${packages[@]}"; do
        echo "Downloading package: $package_name"

        # Download the package file from the apt repository
        apt-get download "$package_name"

        local package_file
        package_file=$(ls | grep "^$package_name.*\.deb$")

        if [ -z "$package_file" ]; then
            echo "Package download failed or file not found: $package_name"
            continue
        fi

        echo "Found downloaded package file: $package_file"

        # Move the downloaded file to the package directory
        mv "$package_file" "$PACKAGE_DIR/"

        # Update packages.txt
        update_package_list "$package_name"
    done
}

# Function to update or create the packages.txt file
function update_package_list {
    local package_name="$1"
    local package_file="$PACKAGE_DIR/$(ls "$PACKAGE_DIR" | grep "^$package_name.*\.deb$")"

    if [ -z "$package_file" ]; then
        echo "Package file for $package_name not found in $PACKAGE_DIR"
        exit 1
    fi

    # Use grep to check if the package already exists
    if grep -q "^$package_name " "$PACKAGES_FILE"; then
        echo "Package $package_name already exists in $PACKAGES_FILE"
        return
    fi

    # Add to packages.txt
    echo "$package_name packages/$(basename "$package_file")" >> "$PACKAGES_FILE"
    echo "Package $package_name added to $PACKAGES_FILE"
}

# Function to list all packages in the repo
function list_packages {
    if [ -f "$PACKAGES_FILE" ]; then
        cat "$PACKAGES_FILE"
    else
        echo "No packages found."
    fi
}

# Function to remove multiple packages from the repo
function remove_packages {
    local packages=("$@")

    if [ "${#packages[@]}" -eq 0 ]; then
        echo "No packages specified to remove."
        exit 1
    fi

    for package_name in "${packages[@]}"; do
        local package_file
        package_file="$PACKAGE_DIR/$(ls "$PACKAGE_DIR" | grep "^$package_name.*\.deb$")"

        if [ -z "$package_file" ]; then
            echo "Package file for $package_name not found in $PACKAGE_DIR"
            continue
        fi

        echo "Removing package file: $(basename "$package_file")"
        rm "$package_file"

        # Update packages.txt to remove the entry
        grep -v "^$package_name " "$PACKAGES_FILE" > "$PACKAGES_FILE.tmp"
        mv "$PACKAGES_FILE.tmp" "$PACKAGES_FILE"
    done
}

# Main script logic
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 {add|list|remove} [package_names...]"
    exit 1
fi

COMMAND="$1"
shift

setup_repo

case "$COMMAND" in
    add)
        add_packages "$@"
        ;;
    list)
        list_packages
        ;;
    remove)
        remove_packages "$@"
        ;;
    *)
        echo "Invalid command. Usage: $0 {add|list|remove} [package_names...]"
        exit 1
        ;;
esac
