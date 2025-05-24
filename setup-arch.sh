#!/bin/bash
# DaVinci Resolve MCP Server Setup for Arch Linux

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DaVinci Resolve MCP Server Setup for Arch Linux ===${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
SERVER_PATH="$SCRIPT_DIR/src/resolve_mcp_server.py"

echo -e "${YELLOW}Project directory: $SCRIPT_DIR${NC}"

# Check if DaVinci Resolve is installed
if [ ! -d "/opt/resolve" ]; then
    echo -e "${RED}✗ DaVinci Resolve not found at /opt/resolve${NC}"
    echo -e "${YELLOW}Please install DaVinci Resolve first${NC}"
    exit 1
fi

echo -e "${GREEN}✓ DaVinci Resolve found at /opt/resolve${NC}"

# Check if DaVinci Resolve is running
if ! pgrep -f "/opt/resolve/bin/resolve" > /dev/null; then
    echo -e "${RED}✗ DaVinci Resolve is not running${NC}"
    echo -e "${YELLOW}Please start DaVinci Resolve before continuing${NC}"
    exit 1
fi

echo -e "${GREEN}✓ DaVinci Resolve is running${NC}"

# Set environment variables for Arch Linux
export RESOLVE_SCRIPT_API="/opt/resolve/Developer/Scripting"
export RESOLVE_SCRIPT_LIB="/opt/resolve/libs/Fusion/fusionscript.so"
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"

echo -e "${YELLOW}Setting environment variables:${NC}"
echo -e "  RESOLVE_SCRIPT_API=$RESOLVE_SCRIPT_API"
echo -e "  RESOLVE_SCRIPT_LIB=$RESOLVE_SCRIPT_LIB"
echo -e "  PYTHONPATH=$PYTHONPATH"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi

# Activate virtual environment and install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$SCRIPT_DIR/requirements.txt"

# Check if the server script exists
if [ ! -f "$SERVER_PATH" ]; then
    echo -e "${RED}✗ Server script not found at $SERVER_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Server script found${NC}"

# Create a launcher script
LAUNCHER_PATH="$SCRIPT_DIR/launch-arch.sh"
cat > "$LAUNCHER_PATH" << 'EOF'
#!/bin/bash
# DaVinci Resolve MCP Server Launcher for Arch Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

# Set environment variables for Arch Linux
export RESOLVE_SCRIPT_API="/opt/resolve/Developer/Scripting"
export RESOLVE_SCRIPT_LIB="/opt/resolve/libs/Fusion/fusionscript.so"
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"

# Activate virtual environment and run server
source "$VENV_DIR/bin/activate"
exec "$VENV_DIR/bin/mcp" dev "$SCRIPT_DIR/src/resolve_mcp_server.py"
EOF

chmod +x "$LAUNCHER_PATH"

# Create environment file for sourcing
ENV_FILE="$SCRIPT_DIR/arch-env.sh"
cat > "$ENV_FILE" << 'EOF'
# Environment variables for DaVinci Resolve MCP Server on Arch Linux
export RESOLVE_SCRIPT_API="/opt/resolve/Developer/Scripting"
export RESOLVE_SCRIPT_LIB="/opt/resolve/libs/Fusion/fusionscript.so"
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"
EOF

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${BLUE}To run the MCP server:${NC}"
echo -e "  ${YELLOW}./launch-arch.sh${NC}"
echo ""
echo -e "${BLUE}To set environment variables in your shell:${NC}"
echo -e "  ${YELLOW}source ./arch-env.sh${NC}"
echo ""
echo -e "${BLUE}For permanent environment variables, add to ~/.bashrc or ~/.zshrc:${NC}"
echo -e "  ${YELLOW}source $(pwd)/arch-env.sh${NC}" 