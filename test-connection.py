#!/usr/bin/env python3
"""
Simple test script to verify DaVinci Resolve connection
"""
import os
import sys

# Set environment variables for Arch Linux
os.environ['RESOLVE_SCRIPT_API'] = '/opt/resolve/Developer/Scripting'
os.environ['RESOLVE_SCRIPT_LIB'] = '/opt/resolve/libs/Fusion/fusionscript.so'
sys.path.append('/opt/resolve/Developer/Scripting/Modules/')

print("Testing DaVinci Resolve connection...")
print(f"RESOLVE_SCRIPT_API: {os.environ.get('RESOLVE_SCRIPT_API')}")
print(f"RESOLVE_SCRIPT_LIB: {os.environ.get('RESOLVE_SCRIPT_LIB')}")
print(f"Python path includes: {'/opt/resolve/Developer/Scripting/Modules/' in sys.path}")

try:
    # Import the DaVinci Resolve module
    import DaVinciResolveScript as dvr_script
    print("✓ Successfully imported DaVinciResolveScript")
    
    # Try to get the Resolve object
    resolve = dvr_script.scriptapp("Resolve")
    if resolve:
        print("✓ Successfully connected to DaVinci Resolve")
        
        # Try to get basic information
        try:
            version = resolve.GetVersion()
            print(f"✓ DaVinci Resolve version: {version}")
        except Exception as e:
            print(f"⚠ Could not get version: {e}")
        
        try:
            product_name = resolve.GetProductName()
            print(f"✓ Product name: {product_name}")
        except Exception as e:
            print(f"⚠ Could not get product name: {e}")
            
        # Try to get project manager
        try:
            project_manager = resolve.GetProjectManager()
            if project_manager:
                print("✓ Successfully got project manager")
                
                # Try to get current project
                try:
                    current_project = project_manager.GetCurrentProject()
                    if current_project:
                        project_name = current_project.GetName()
                        print(f"✓ Current project: {project_name}")
                    else:
                        print("⚠ No current project open")
                except Exception as e:
                    print(f"⚠ Could not get current project: {e}")
            else:
                print("✗ Could not get project manager")
        except Exception as e:
            print(f"✗ Error getting project manager: {e}")
            
    else:
        print("✗ Failed to connect to DaVinci Resolve")
        
except ImportError as e:
    print(f"✗ Failed to import DaVinciResolveScript: {e}")
    print("Make sure DaVinci Resolve is running and the scripting module is available")
except Exception as e:
    print(f"✗ Unexpected error: {e}")

print("\nTest completed.") 