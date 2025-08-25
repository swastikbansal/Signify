"""
Simple script to visualize coordinates received from your API in 2D
This gives you an immediate visual of what your model is seeing
"""

import requests
import json
import matplotlib.pyplot as plt
import numpy as np
from coordinate_compare import CoordinateAnalyzer
import os
import cv2

def test_api_and_visualize(api_url="http://192.168.29.42:5000"):
    """Test API connection and show recent coordinate data"""
    
    # Test API connection
    try:
        response = requests.get(f"{api_url}/health")
        if response.status_code != 200:
            print(f"❌ API not accessible: {response.status_code}")
            return
        print("✅ API is accessible")
    except Exception as e:
        print(f"❌ API connection failed: {e}")
        return
    
    # Enable debug mode
    try:
        response = requests.post(f"{api_url}/debug/toggle")
        if response.status_code == 200:
            debug_status = response.json().get('debug_mode', False)
            print(f"✅ Debug mode: {'ON' if debug_status else 'OFF'}")
        else:
            print("⚠️ Could not toggle debug mode")
    except Exception as e:
        print(f"⚠️ Debug toggle failed: {e}")
    
    # Get list of debug files
    try:
        response = requests.get(f"{api_url}/debug/files")
        if response.status_code == 200:
            files_data = response.json()
            files = files_data.get('files', [])
            
            if files:
                print(f"✅ Found {len(files)} debug files")
                
                # Get the most recent file
                latest_file = files[0]  # Already sorted by creation time
                print(f"📄 Latest file: {latest_file['filename']}")
                
                # Load and visualize the latest coordinates
                analyzer = CoordinateAnalyzer()
                file_path = latest_file['filepath']
                
                try:
                    data = analyzer.load_coordinate_file(file_path)
                    print("🎯 Visualizing latest coordinates...")
                    analyzer.quick_2d_plot(data, f"Latest API Data: {latest_file['filename']}")
                    
                    # Also show statistics
                    print("\n📊 Coordinate Statistics:")
                    for coord_type in ['left_hand', 'right_hand', 'pose']:
                        coords = data.get(coord_type)
                        if coords:
                            stats = analyzer.analyze_single_coordinate_set(coords, coord_type)
                            if stats and 'overall' in stats:
                                print(f"  {coord_type:>12}: Count={stats['count']:>3}, "
                                      f"Mean={stats['overall']['mean']:>8.4f}, "
                                      f"Range=[{stats['overall']['min']:>6.3f}, {stats['overall']['max']:>6.3f}]")
                    
                except Exception as e:
                    print(f"❌ Failed to load coordinate file: {e}")
            else:
                print("📭 No debug files found. Send some coordinates to the API first!")
                print("💡 Try running your test.py script to generate coordinate data")
        else:
            print(f"❌ Could not get debug files list: {response.status_code}")
    except Exception as e:
        print(f"❌ Failed to get debug files: {e}")

if __name__ == "__main__":
    print("🎯 Coordinate Visualization Tool")
    print("=" * 40)
    print("Commands:")
    print("  python visualize_coords.py test     - Test API and show latest coordinates")
    print()
    print("Quick test:")
    test_api_and_visualize()
