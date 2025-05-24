# DaVinci Resolve MCP Server - Arch Linux Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the DaVinci Resolve MCP (Model Context Protocol) server on Arch Linux. The MCP server allows AI assistants like Claude to control DaVinci Resolve Studio through its scripting API.

## Prerequisites

- **DaVinci Resolve Studio** installed at `/opt/resolve/`
- **Python 3.9+** (tested with Python 3.12)
- **DaVinci Resolve running** before starting the MCP server

## Verified System Configuration

- **OS**: Arch Linux (kernel 6.14.6-arch1-1)
- **DaVinci Resolve**: Studio version 20.0.0.23
- **Python**: 3.12.9
- **Installation Path**: `/opt/resolve/`

## Quick Setup

### 1. Automated Setup (Recommended)

```bash
# Navigate to the MCP server directory
cd MCP/davinci-resolve-mcp

# Run the Arch Linux setup script
chmod +x setup-arch.sh
./setup-arch.sh
```

### 2. Launch the Server

```bash
# Use the generated launcher
./launch-arch.sh
```

### 3. Test the Connection

```bash
# Run the connection test
source venv/bin/activate
python test-connection.py
```

## Manual Setup

If you prefer manual setup or encounter issues:

### 1. Environment Variables

Set the following environment variables for Arch Linux:

```bash
export RESOLVE_SCRIPT_API="/opt/resolve/Developer/Scripting"
export RESOLVE_SCRIPT_LIB="/opt/resolve/libs/Fusion/fusionscript.so"
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"
```

### 2. Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Run the Server

```bash
# Start the MCP server in development mode
venv/bin/mcp dev src/resolve_mcp_server.py
```

## Verification

### Connection Test Results

When properly configured, you should see:

```
Testing DaVinci Resolve connection...
✓ Successfully imported DaVinciResolveScript
✓ Successfully connected to DaVinci Resolve
✓ DaVinci Resolve version: [20, 0, 0, 23, 'b']
✓ Product name: DaVinci Resolve Studio
✓ Successfully got project manager
✓ Current project: [Your Project Name]
```

### MCP Functionality Test

The comprehensive test should show:

```
✓ Basic connection: Working
✓ Project operations: Working
✓ Timeline operations: Working
✓ Media pool operations: Working
✓ Color page operations: Working

🎉 DaVinci Resolve MCP integration is fully functional!
```

## Available MCP Tools

The server provides extensive functionality including:

### Project Management
- Create, open, save, and close projects
- Set project settings and properties
- Manage cloud projects

### Timeline Operations
- Create, delete, and switch timelines
- Add markers with colors and notes
- Set timeline format and properties

### Media Management
- Import media files
- Create and manage bins
- Auto-sync audio
- Link/unlink proxy media
- Transcribe audio

### Color Grading
- Apply LUTs
- Set color wheel parameters
- Add and manage nodes
- Copy grades between clips
- Save and apply color presets

### Rendering
- Add to render queue
- Start/stop rendering
- Clear render queue

### Advanced Features
- Keyframe animation
- Timeline item transformations
- Stabilization
- Audio properties
- Export operations

## Troubleshooting

### Common Issues

1. **"DaVinci Resolve not running"**
   - Ensure DaVinci Resolve is launched before starting the MCP server
   - Check with: `ps aux | grep resolve`

2. **Import errors**
   - Verify environment variables are set correctly
   - Check that `/opt/resolve/Developer/Scripting/Modules/` exists

3. **Permission issues**
   - Ensure your user has access to `/opt/resolve/`
   - Check file permissions on the scripting modules

### Environment Files

The setup creates these files for convenience:

- `arch-env.sh` - Environment variables for manual sourcing
- `launch-arch.sh` - Complete launcher script

## Integration with AI Assistants

Once running, the MCP server can be used with AI assistants that support the Model Context Protocol. The server provides a comprehensive API for controlling all aspects of DaVinci Resolve.

### Example Usage

```python
# Through MCP tools, you can:
# - Switch between pages (Media, Cut, Edit, Fusion, Color, Fairlight, Deliver)
# - Create and manage timelines
# - Import and organize media
# - Apply color corrections and effects
# - Set up rendering jobs
# - And much more!
```

## Performance Notes

- The MCP server has minimal overhead
- DaVinci Resolve Studio's scripting API is responsive
- Multiple MCP server instances can run simultaneously
- Memory usage is typically under 100MB

## Next Steps

With the MCP server working, you can:

1. **Integrate with Cursor AI** - Use the server for AI-assisted video editing
2. **Automate workflows** - Create scripts for repetitive tasks
3. **Build custom tools** - Extend functionality for specific needs
4. **Explore Rust rewrite** - Consider performance improvements

## Support

For issues specific to Arch Linux setup:
- Check DaVinci Resolve installation path
- Verify Python environment
- Ensure all dependencies are installed
- Test connection with provided scripts

The MCP server is now ready for production use on your Arch Linux system! 