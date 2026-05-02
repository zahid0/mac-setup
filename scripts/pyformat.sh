#!/bin/bash

# Simple version with guard clause

set -e

echo "Checking required packages..."

# Function to check and install missing packages
check_and_install() {
    if ! command -v "$1" &> /dev/null; then
        echo "Missing: $1"
        MISSING_PACKAGES+=("$1")
    fi
}

MISSING_PACKAGES=()
check_and_install "autoflake"
check_and_install "isort"
check_and_install "black"
check_and_install "flake8"

# Guard clause
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "Missing required packages: ${MISSING_PACKAGES[*]}"
    read -p "Do you want to install them now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing: ${MISSING_PACKAGES[*]}"
        pip install "${MISSING_PACKAGES[@]}"
    else
        echo "Cannot continue without required packages. Exiting."
        exit 1
    fi
fi

echo "All dependencies satisfied. Running formatting and linting..."

autoflake --in-place --remove-all-unused-imports --remove-unused-variables --remove-duplicate-keys -r .

isort . --profile black

black .

flake8 . --exclude='node_modules,.venv,__pycache__' --ignore=E203,E501,W503
