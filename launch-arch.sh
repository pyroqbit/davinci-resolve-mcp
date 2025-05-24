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
