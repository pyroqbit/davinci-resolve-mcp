#!/bin/bash
# Pre-launch Check Script for DaVinci Resolve MCP
# This script verifies that DaVinci Resolve is running and all required components are installed
# before launching Cursor

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VENV_DIR="$SCRIPT_DIR/venv"
CURSOR_CONFIG_FILE="$HOME/.cursor/mcp.json"
RESOLVE_MCP_SERVER="$SCRIPT_DIR/resolve_mcp_server.py"

# Required files and their permissions
REQUIRED_FILES=(
    "$SCRIPT_DIR/resolve_mcp_server.py:755"
    "$SCRIPT_DIR/run-now.sh:755"
    "$SCRIPT_DIR/setup.sh:755"
)

# Function to check if DaVinci Resolve is running
check_resolve_running() {
    # Look for the actual process name "Resolve" (not "DaVinci Resolve")
    if pgrep -x "Resolve" > /dev/null; then
        return 0 # Running
    else
        return 1 # Not running
    fi
}

# Function to check environment variables
check_resolve_env() {
    # For Linux, if not set, try to set them based on common Arch Linux path
    if [[ "$(uname -s)" == "Linux" ]]; then
        if [ -z "$RESOLVE_SCRIPT_API" ]; then
            export RESOLVE_SCRIPT_API="/opt/resolve/Developer/Scripting"
            echo -e "${YELLOW}RESOLVE_SCRIPT_API was not set. Assuming Arch Linux default: /opt/resolve/Developer/Scripting${NC}"
        fi
        if [ -z "$RESOLVE_SCRIPT_LIB" ]; then
            export RESOLVE_SCRIPT_LIB="/opt/resolve/libs/Fusion/fusionscript.so"
            echo -e "${YELLOW}RESOLVE_SCRIPT_LIB was not set. Assuming Arch Linux default: /opt/resolve/libs/Fusion/fusionscript.so${NC}"
        fi
        # Ensure PYTHONPATH is also set
        if [[ -z "$PYTHONPATH" || "$PYTHONPATH" != *"$RESOLVE_SCRIPT_API/Modules/"* ]]; then
            export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"
             echo -e "${YELLOW}PYTHONPATH updated for Resolve Scripting API Modules.${NC}"
        fi
    fi

    if [ -z "$RESOLVE_SCRIPT_API" ] || [ -z "$RESOLVE_SCRIPT_LIB" ]; then
        return 1 # Not set
    else
        return 0 # Set
    fi
}

# Function to check if the virtual environment exists and has MCP installed
check_venv() {
    if [ ! -d "$VENV_DIR" ] || [ ! -f "$VENV_DIR/bin/python" ]; then
        return 1 # Missing
    fi
    
    if ! "$VENV_DIR/bin/pip" list | grep -q "mcp"; then
        return 2 # Missing MCP
    fi
    
    return 0 # All good
}

# Function to check all required files and permissions
check_required_files() {
    local missing_files=()
    local wrong_permissions=()
    
    for req in "${REQUIRED_FILES[@]}"; do
        IFS=':' read -r file perm <<< "$req"
        
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        elif [ "$(stat -f '%A' "$file")" != "$perm" ]; then
            wrong_permissions+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing required files:${NC}"
        for file in "${missing_files[@]}"; do
            echo -e "  - $file"
        done
        return 1
    fi
    
    if [ ${#wrong_permissions[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠ Some files have incorrect permissions:${NC}"
        for file in "${wrong_permissions[@]}"; do
            echo -e "  - $file"
        done
        return 2
    fi
    
    return 0
}

# Function to check if cursor config is properly set
check_cursor_config() {
    if [ ! -f "$CURSOR_CONFIG_FILE" ]; then
        return 1 # Missing
    fi
    
    if ! grep -q "davinci-resolve" "$CURSOR_CONFIG_FILE"; then
        return 2 # Missing config
    fi
    
    return 0 # All good
}

# Print header
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  DaVinci Resolve MCP Pre-Launch Check                        ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check 0: Required files and scripts
echo -e "${YELLOW}Checking required files and scripts...${NC}"
files_status=$(check_required_files)
file_check_result=$?

if [ "$file_check_result" -eq 0 ]; then
    echo -e "${GREEN}✓ All required files are present with correct permissions${NC}"
elif [ "$file_check_result" -eq 2 ]; then
    echo -e "${YELLOW}Fixing file permissions...${NC}"
    for req in "${REQUIRED_FILES[@]}"; do
        IFS=':' read -r file perm <<< "$req"
        if [ -f "$file" ]; then
            chmod "$perm" "$file"
            echo -e "  - Fixed permissions for $file"
        fi
    done
    echo -e "${GREEN}✓ File permissions fixed${NC}"
else
    echo -e "${RED}✗ Some required files are missing${NC}"
    echo -e "${YELLOW}Attempting to retrieve or recreate missing files...${NC}"
    
    # Check if resolve_mcp_server.py is missing and create a basic version if needed
    if [ ! -f "$RESOLVE_MCP_SERVER" ]; then
        echo -e "${YELLOW}Creating basic resolve_mcp_server.py...${NC}"
        cat > "$RESOLVE_MCP_SERVER" << 'EOF'
#!/usr/bin/env python3
"""
DaVinci Resolve MCP Server
A server that connects to DaVinci Resolve via the Model Context Protocol (MCP)

Version: 1.3.8 - Basic Server (with Linux path awareness)
"""

import os
import sys
import logging
from mcp.server.fastmcp import FastMCP

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("davinci-resolve-mcp")

# Log server version and platform
VERSION = "1.3.8"
logger.info(f"Starting DaVinci Resolve MCP Server v{VERSION}")

# Create MCP server instance
mcp = FastMCP("DaVinciResolveMCP")

# Initialize connection to DaVinci Resolve
def initialize_resolve():
    """Initialize connection to DaVinci Resolve application."""
    try:
        # Import the DaVinci Resolve scripting module
        import DaVinciResolveScript as dvr_script
        
        # Get the resolve object
        resolve = dvr_script.scriptapp("Resolve")
        
        if resolve is None:
            logger.error("Failed to get Resolve object. Is DaVinci Resolve running?")
            return None
        
        logger.info(f"Connected to DaVinci Resolve: {resolve.GetProductName()} {resolve.GetVersionString()}")
        return resolve
    
    except ImportError:
        logger.error("Failed to import DaVinciResolveScript. Check environment variables.")
        logger.error("RESOLVE_SCRIPT_API, RESOLVE_SCRIPT_LIB, and PYTHONPATH must be set correctly.")
        if sys.platform == "darwin": # macOS specific paths
            logger.error("On macOS, typically:")
            logger.error('export RESOLVE_SCRIPT_API="/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"')
            logger.error('export RESOLVE_SCRIPT_LIB="/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"')
        elif sys.platform.startswith("linux"): # Linux specific paths
            logger.error("On Linux (e.g., Arch based on /opt/resolve):")
            logger.error('export RESOLVE_SCRIPT_API="/opt/resolve/Developer/Scripting"')
            logger.error('export RESOLVE_SCRIPT_LIB="/opt/resolve/libs/Fusion/fusionscript.so"')
        logger.error('export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"') # Common for both
        return None
    
    except Exception as e:
        logger.error(f"Unexpected error initializing Resolve: {str(e)}")
        return None

# Initialize Resolve once at startup
resolve = initialize_resolve()

# ------------------
# MCP Tools/Resources
# ------------------

@mcp.resource("resolve://version")
def get_resolve_version() -> str:
    """Get DaVinci Resolve version information."""
    if resolve is None:
        return "Error: Not connected to DaVinci Resolve"
    return f"{resolve.GetProductName()} {resolve.GetVersionString()}"

@mcp.resource("resolve://current-page")
def get_current_page() -> str:
    """Get the current page open in DaVinci Resolve (Edit, Color, Fusion, etc.)."""
    if resolve is None:
        return "Error: Not connected to DaVinci Resolve"
    return resolve.GetCurrentPage()

@mcp.tool()
def switch_page(page: str) -> str:
    """Switch to a specific page in DaVinci Resolve.
    
    Args:
        page: The page to switch to. Options: 'media', 'cut', 'edit', 'fusion', 'color', 'fairlight', 'deliver'
    """
    if resolve is None:
        return "Error: Not connected to DaVinci Resolve"
    
    valid_pages = ['media', 'cut', 'edit', 'fusion', 'color', 'fairlight', 'deliver']
    page = page.lower()
    
    if page not in valid_pages:
        return f"Error: Invalid page. Choose from {', '.join(valid_pages)}"
    
    resolve.OpenPage(page.capitalize()) # Resolve API expects capitalized page names
    return f"Successfully switched to {page} page"

# Start the server
if __name__ == "__main__":
    try:
        if resolve is None:
            logger.error("Server started but not connected to DaVinci Resolve.")
            logger.error("Make sure DaVinci Resolve is running and environment variables are correctly set.")
        else:
            logger.info("Successfully connected to DaVinci Resolve.")
        
        logger.info("Starting DaVinci Resolve MCP Server")
        mcp.run()
    except KeyboardInterrupt:
        logger.info("Server shutdown requested")
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        sys.exit(1)
EOF
        chmod 755 "$RESOLVE_MCP_SERVER"
        echo -e "${GREEN}✓ Created basic resolve_mcp_server.py${NC}"
    fi
    
    # Check if setup.sh is missing and create it
    if [ ! -f "$SCRIPT_DIR/setup.sh" ]; then
        echo -e "${YELLOW}Creating setup.sh...${NC}"
        cat > "$SCRIPT_DIR/setup.sh" << 'EOF'
#!/bin/bash
# Setup script for DaVinci Resolve MCP Server

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VENV_DIR="$SCRIPT_DIR/venv"
PYTHON_EXEC="python3" # Use python3 by default

echo "Starting DaVinci Resolve MCP Server setup..."

# Detect OS
OS_TYPE=$(uname -s)
echo "Detected OS: $OS_TYPE"

# Set Resolve environment variables if not already set
if [[ "$OS_TYPE" == "Darwin" ]]; then # macOS
    : "${RESOLVE_SCRIPT_API:=/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting}"
    : "${RESOLVE_SCRIPT_LIB:=/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so}"
    echo "Using macOS paths for Resolve scripting."
elif [[ "$OS_TYPE" == "Linux" ]]; then # Linux
    : "${RESOLVE_SCRIPT_API:=/opt/resolve/Developer/Scripting}"
    : "${RESOLVE_SCRIPT_LIB:=/opt/resolve/libs/Fusion/fusionscript.so}"
    echo "Using Linux (Arch/opt) paths for Resolve scripting."
else
    echo "Unsupported OS for automatic Resolve path detection: $OS_TYPE"
    echo "Please set RESOLVE_SCRIPT_API and RESOLVE_SCRIPT_LIB manually if DaVinci Resolve is installed."
fi

# Export environment variables
export RESOLVE_SCRIPT_API
export RESOLVE_SCRIPT_LIB
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"

echo "RESOLVE_SCRIPT_API: $RESOLVE_SCRIPT_API"
echo "RESOLVE_SCRIPT_LIB: $RESOLVE_SCRIPT_LIB"
echo "PYTHONPATH: $PYTHONPATH"

# Check if Python 3 is available
if ! command -v $PYTHON_EXEC &> /dev/null; then
    echo "Error: $PYTHON_EXEC is not installed or not in PATH."
    exit 1
fi
echo "Using Python: $($PYTHON_EXEC --version)"

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment in $VENV_DIR..."
    $PYTHON_EXEC -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create virtual environment."
        exit 1
    fi
else
    echo "Virtual environment already exists at $VENV_DIR."
fi

# Activate virtual environment (for this script's context)
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

# Install/Upgrade requirements
echo "Installing/upgrading requirements from requirements.txt..."
if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install --upgrade pip
    "$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install requirements."
        # Deactivate venv before exiting if sourced
        type deactivate &>/dev/null && deactivate
        exit 1
    fi
else
    echo "Warning: requirements.txt not found in $SCRIPT_DIR. Skipping dependency installation."
    echo "Please ensure 'mcp' and other necessary packages are installed manually in the venv."
fi

echo "Setup complete."
echo "To activate the environment, run: source $VENV_DIR/bin/activate"
echo "To run the server, use: $VENV_DIR/bin/python $SCRIPT_DIR/resolve_mcp_server.py or ./run-now.sh"

# Deactivate venv if sourced
type deactivate &>/dev/null && deactivate
EOF
        chmod 755 "$SCRIPT_DIR/setup.sh"
        echo -e "${GREEN}✓ Created setup.sh${NC}"
    fi

    # Check if run-now.sh is missing and create it
    if [ ! -f "$SCRIPT_DIR/run-now.sh" ]; then
        echo -e "${YELLOW}Creating run-now.sh...${NC}"
        cat > "$SCRIPT_DIR/run-now.sh" << 'EOF'
#!/bin/bash
# Script to run the DaVinci Resolve MCP Server directly

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VENV_DIR="$SCRIPT_DIR/venv"
RESOLVE_SERVER_SCRIPT="$SCRIPT_DIR/resolve_mcp_server.py"

echo "Attempting to start DaVinci Resolve MCP Server..."

# Detect OS
OS_TYPE=$(uname -s)
echo "Detected OS: $OS_TYPE"

# Set Resolve environment variables if not already set
if [[ "$OS_TYPE" == "Darwin" ]]; then # macOS
    : "${RESOLVE_SCRIPT_API:=/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting}"
    : "${RESOLVE_SCRIPT_LIB:=/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so}"
elif [[ "$OS_TYPE" == "Linux" ]]; then # Linux
    : "${RESOLVE_SCRIPT_API:=/opt/resolve/Developer/Scripting}"
    : "${RESOLVE_SCRIPT_LIB:=/opt/resolve/libs/Fusion/fusionscript.so}"
else
    echo "Warning: Unsupported OS for automatic Resolve path detection: $OS_TYPE"
    echo "Ensure RESOLVE_SCRIPT_API and RESOLVE_SCRIPT_LIB are set if DaVinci Resolve is installed."
fi

# Export environment variables
export RESOLVE_SCRIPT_API
export RESOLVE_SCRIPT_LIB
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"

echo "Using RESOLVE_SCRIPT_API: $RESOLVE_SCRIPT_API"
echo "Using RESOLVE_SCRIPT_LIB: $RESOLVE_SCRIPT_LIB"
echo "Using PYTHONPATH: $PYTHONPATH"

# Check if DaVinci Resolve is running
if ! pgrep -x "Resolve" > /dev/null; then
    echo "Error: DaVinci Resolve process 'Resolve' not found."
    echo "Please start DaVinci Resolve before running this server."
    exit 1
fi
echo "DaVinci Resolve process found."

# Check if server script exists
if [ ! -f "$RESOLVE_SERVER_SCRIPT" ]; then
    echo "Error: Server script $RESOLVE_SERVER_SCRIPT not found."
    echo "Please run setup.sh first or ensure the script exists."
    exit 1
fi

# Check if venv exists and activate it
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
    echo "Activating virtual environment: $VENV_DIR"
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
else
    echo "Error: Virtual environment not found at $VENV_DIR."
    echo "Please run setup.sh to create the virtual environment."
    exit 1
fi

# Run the server
echo "Starting server: $VENV_DIR/bin/python $RESOLVE_SERVER_SCRIPT"
"$VENV_DIR/bin/python" "$RESOLVE_SERVER_SCRIPT"

# Deactivate venv (will only run if script exits gracefully)
type deactivate &>/dev/null && deactivate

echo "Server exited."
EOF
        chmod 755 "$SCRIPT_DIR/run-now.sh"
        echo -e "${GREEN}✓ Created run-now.sh${NC}"
    fi
    # Re-run the file check after attempting to create missing ones
    files_status=$(check_required_files)
    file_check_result=$?
    if [ "$file_check_result" -ne 0 ]; then
        echo -e "${RED}✗ Still missing required files or permissions after attempting recreation. Please check manually.${NC}"
        exit 1
    fi
fi

# Check 1: Is DaVinci Resolve running?
echo -e "${YELLOW}Checking if DaVinci Resolve is running...${NC}"
if check_resolve_running; then
    echo -e "${GREEN}✓ DaVinci Resolve is running${NC}"
else
    echo -e "${RED}✗ DaVinci Resolve is NOT running${NC}"
    echo -e "${YELLOW}Please start DaVinci Resolve before launching Cursor${NC}"
    
    # Ask if user wants to start DaVinci Resolve
    read -p "Would you like to start DaVinci Resolve now? (y/n): " start_resolve
    if [[ "$start_resolve" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Starting DaVinci Resolve...${NC}"
        open -a "DaVinci Resolve"
        echo -e "${YELLOW}Waiting for DaVinci Resolve to start...${NC}"
        sleep 5
        
        # Check again
        if check_resolve_running; then
            echo -e "${GREEN}✓ DaVinci Resolve started successfully${NC}"
        else
            echo -e "${YELLOW}DaVinci Resolve is starting. Please wait until it's fully loaded before proceeding.${NC}"
        fi
    else
        echo -e "${RED}DaVinci Resolve must be running for the MCP server to function properly.${NC}"
        exit 1
    fi
fi

# Check 2: Environment variables
echo -e "${YELLOW}Checking Resolve environment variables...${NC}"
if check_resolve_env; then
    echo -e "${GREEN}✓ Resolve environment variables are set${NC}"
    echo -e "  RESOLVE_SCRIPT_API = $RESOLVE_SCRIPT_API"
    echo -e "  RESOLVE_SCRIPT_LIB = $RESOLVE_SCRIPT_LIB"
else
    echo -e "${RED}✗ Resolve environment variables are NOT set${NC}"
    echo -e "${YELLOW}Setting default environment variables...${NC}"
    
    # Set default paths for macOS
    export RESOLVE_SCRIPT_API="/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
    export RESOLVE_SCRIPT_LIB="/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"
    export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"
    
    echo -e "${GREEN}✓ Environment variables set for this session:${NC}"
    echo -e "  RESOLVE_SCRIPT_API = $RESOLVE_SCRIPT_API"
    echo -e "  RESOLVE_SCRIPT_LIB = $RESOLVE_SCRIPT_LIB"
    echo -e "${YELLOW}Note: These variables are only set for this session. For permanent setup, run ./setup.sh${NC}"
fi

# Check 3: Virtual environment
echo -e "${YELLOW}Checking Python virtual environment...${NC}"
venv_status=$(check_venv)
if [ "$venv_status" -eq 0 ]; then
    echo -e "${GREEN}✓ Virtual environment is set up correctly with MCP installed${NC}"
elif [ "$venv_status" -eq 2 ]; then
    echo -e "${RED}✗ MCP is not installed in the virtual environment${NC}"
    echo -e "${YELLOW}Installing MCP...${NC}"
    "$VENV_DIR/bin/pip" install mcp[cli]
    echo -e "${GREEN}✓ MCP installed${NC}"
else
    echo -e "${RED}✗ Virtual environment is missing or incomplete${NC}"
    echo -e "${YELLOW}Setting up virtual environment...${NC}"
    
    # Create virtual environment
    python3 -m venv "$VENV_DIR"
    
    # Install MCP
    "$VENV_DIR/bin/pip" install mcp[cli]
    
    echo -e "${GREEN}✓ Virtual environment created and MCP installed${NC}"
fi

# Check 4: Cursor configuration
echo -e "${YELLOW}Checking Cursor configuration...${NC}"
cursor_status=$(check_cursor_config)
if [ "$cursor_status" -eq 0 ]; then
    echo -e "${GREEN}✓ Cursor is configured to use the DaVinci Resolve MCP server${NC}"
elif [ "$cursor_status" -eq 1 ]; then
    echo -e "${RED}✗ Cursor configuration file is missing${NC}"
    echo -e "${YELLOW}Creating Cursor configuration...${NC}"
    
    # Create directory if it doesn't exist
    mkdir -p "$HOME/.cursor"
    
    # Create config file
    cat > "$CURSOR_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "davinci-resolve": {
      "name": "DaVinci Resolve MCP",
      "command": "$VENV_DIR/bin/python",
      "args": ["$SCRIPT_DIR/../src/main.py"]
    }
  }
}
EOF
    echo -e "${GREEN}✓ Cursor configuration created${NC}"
else
    echo -e "${RED}✗ Cursor configuration is missing DaVinci Resolve MCP settings${NC}"
    echo -e "${YELLOW}Updating Cursor configuration...${NC}"
    
    # Backup existing config
    cp "$CURSOR_CONFIG_FILE" "$CURSOR_CONFIG_FILE.bak"
    
    # Update config file - this is a simple approach that assumes the file is valid JSON
    # A more robust approach would use jq if available
    if grep -q "\"mcpServers\"" "$CURSOR_CONFIG_FILE"; then
        # mcpServers already exists, try to add our server
        sed -i '' -e 's/"mcpServers": {/"mcpServers": {\n    "davinci-resolve": {\n      "name": "DaVinci Resolve MCP",\n      "command": "'"$VENV_DIR\/bin\/python"'",\n      "args": ["'"$SCRIPT_DIR/../src/main.py"'"]\n    },/g' "$CURSOR_CONFIG_FILE"
    else
        # No mcpServers exists, create everything
        cat > "$CURSOR_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "davinci-resolve": {
      "name": "DaVinci Resolve MCP",
      "command": "$VENV_DIR/bin/python",
      "args": ["$SCRIPT_DIR/../src/main.py"]
    }
  }
}
EOF
    fi
    
    echo -e "${GREEN}✓ Cursor configuration updated${NC}"
fi

# Final message
echo ""
echo -e "${GREEN}All checks complete!${NC}"
echo -e "${GREEN}Your system is ready to use DaVinci Resolve with Cursor.${NC}"
echo ""

# Ask if user wants to launch Cursor
read -p "Would you like to launch Cursor now? (y/n): " launch_cursor
if [[ "$launch_cursor" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Launching Cursor...${NC}"
    open -a "Cursor"
    echo -e "${GREEN}Cursor launched. Enjoy using DaVinci Resolve with AI assistance!${NC}"
fi

exit 0 