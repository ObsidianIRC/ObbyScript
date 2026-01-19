#!/bin/bash
#
# UnrealIRCd JavaScript Module Installer
# 
# This script installs the JavaScript scripting module into your UnrealIRCd installation.
#
# Usage: ./install.sh [unrealircd-source-directory]
#
# If no directory is specified, it will try common locations.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═════════════════════════════════════════════════╗"
echo "║     UnrealIRCd JavaScript Module Installer      ║"
echo "║     Powered by Duktape JavaScript Engine        ║"
echo "╚═════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to find UnrealIRCd runtime directory
find_unrealircd_runtime() {
    local source_dir="$1"
    
    # Check config.settings for BASEPATH
    if [[ -f "$source_dir/config.settings" ]]; then
        local basepath=$(grep "^BASEPATH=" "$source_dir/config.settings" | cut -d'"' -f2)
        if [[ -n "$basepath" ]]; then
            local runtime_dir
            if [[ "$basepath" == /* ]]; then
                runtime_dir="$basepath"
            else
                runtime_dir="$HOME/$basepath"
            fi
            if [[ -d "$runtime_dir" && -d "$runtime_dir/conf" && -d "$runtime_dir/modules" ]]; then
                echo "$runtime_dir"
                return 0
            fi
        fi
    fi
    
    return 1
}

# Parse command line argument
UNREALIRCD_SOURCE="$1"

# Find UnrealIRCd source directory
if [[ -z "$UNREALIRCD_SOURCE" ]]; then
    read -p "Enter UnrealIRCd source directory: " UNREALIRCD_SOURCE
    if [[ -z "$UNREALIRCD_SOURCE" ]]; then
        echo -e "${RED}No directory entered.${NC}"
        exit 1
    fi
fi

if [[ -z "$UNREALIRCD_SOURCE" || ! -d "$UNREALIRCD_SOURCE" ]]; then
    echo -e "${RED}Error: Could not find UnrealIRCd source directory.${NC}"
    echo ""
    echo "Usage: $0 <unrealircd-source-directory>"
    echo ""
    echo "Example:"
    echo "  $0 ~/unrealircd-6.2.2"
    echo "  $0 /usr/local/src/unrealircd"
    echo ""
    exit 1
fi

# Verify it's a valid UnrealIRCd source tree
if [[ ! -f "$UNREALIRCD_SOURCE/configure.ac" ]]; then
    echo -e "${RED}Error: $UNREALIRCD_SOURCE doesn't appear to be an UnrealIRCd source directory.${NC}"
    exit 1
fi

if [[ ! -d "$UNREALIRCD_SOURCE/src/modules/third" ]]; then
    echo -e "${YELLOW}Creating third-party modules directory...${NC}"
    mkdir -p "$UNREALIRCD_SOURCE/src/modules/third"
fi

echo -e "${GREEN}Found UnrealIRCd source:${NC} $UNREALIRCD_SOURCE"

# Find runtime directory
UNREALIRCD_RUNTIME=$(find_unrealircd_runtime "$UNREALIRCD_SOURCE")
if [[ -n "$UNREALIRCD_RUNTIME" ]]; then
    echo -e "${GREEN}Found UnrealIRCd runtime:${NC} $UNREALIRCD_RUNTIME"
else
    echo -e "${YELLOW}Warning: Could not find UnrealIRCd runtime directory.${NC}"
    echo -e "${YELLOW}You may need to run 'make install' after building.${NC}"
fi

# Copy source files
echo ""
echo -e "${BLUE}Installing source files...${NC}"

THIRD_DIR="$UNREALIRCD_SOURCE/src/modules/third"

cp -v "$SCRIPT_DIR/obbyscript.c" "$THIRD_DIR/"
cp -v "$SCRIPT_DIR/duktape.c" "$THIRD_DIR/"
cp -v "$SCRIPT_DIR/duktape.h" "$THIRD_DIR/"
cp -v "$SCRIPT_DIR/duk_config.h" "$THIRD_DIR/"

echo -e "${GREEN}Source files installed.${NC}"

# Build the module
echo ""
echo -e "${BLUE}Building the module...${NC}"

cd "$UNREALIRCD_SOURCE"

# Check if UnrealIRCd has been configured
if [[ ! -f "config.settings" ]]; then
    echo -e "${RED}Error: UnrealIRCd has not been configured yet.${NC}"
    echo "Please run ./Config first, then re-run this installer."
    exit 1
fi

# Build with -lm (required for Duktape math functions like log2, pow, etc.)
EXLIBS="-lm" make

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Install the module
echo ""
echo -e "${BLUE}Installing the module...${NC}"

make install

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Installation failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Module installed!${NC}"

# Create scripts directory in runtime location
if [[ -n "$UNREALIRCD_RUNTIME" ]]; then
    SCRIPTS_DIR="$UNREALIRCD_RUNTIME/conf/scripts"
    if [[ ! -d "$SCRIPTS_DIR" ]]; then
        echo ""
        echo -e "${BLUE}Creating scripts directory...${NC}"
        mkdir -p "$SCRIPTS_DIR"
        echo -e "${GREEN}Created:${NC} $SCRIPTS_DIR"
    fi
fi

# Final instructions
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Installation Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}To enable the module, add this line to your unrealircd.conf:${NC}"
echo ""
echo -e "    ${BLUE}loadmodule \"third/obbyscript\";${NC}"
echo ""
echo -e "${YELLOW}Then rehash your server:${NC}"
echo ""
echo -e "    ${BLUE}/REHASH${NC}"
echo ""
if [[ -n "$UNREALIRCD_RUNTIME" ]]; then
    echo -e "${YELLOW}Place your JavaScript scripts in:${NC}"
    echo ""
    echo -e "    ${BLUE}$SCRIPTS_DIR/${NC}"
    echo ""
fi
echo -e "${YELLOW}See README.md for documentation and examples.${NC}"
echo ""
