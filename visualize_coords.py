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

def live_coordinate_monitor(api_url="http://192.168.29.42:5000", interval=2):
    """Monitor coordinates in real-time (simplified version)"""
    print("🔄 Starting coordinate monitor...")
    print("   Send coordinates to /predict to see them visualized")
    print("   Press Ctrl+C to stop")
    
    analyzer = CoordinateAnalyzer()
    previous_file_count = 0
    
    try:
        while True:
            import time
            time.sleep(interval)
            
            # Check for new debug files
            try:
                response = requests.get(f"{api_url}/debug/files")
                if response.status_code == 200:
                    files_data = response.json()
                    current_file_count = files_data.get('file_count', 0)
                    
                    if current_file_count > previous_file_count:
                        print(f"🆕 New coordinate data detected! ({current_file_count} total files)")
                        
                        # Visualize the latest file
                        files = files_data.get('files', [])
                        if files:
                            latest_file = files[0]
                            data = analyzer.load_coordinate_file(latest_file['filepath'])
                            analyzer.quick_2d_plot(data, f"Live Data: {latest_file['filename']}")
                        
                        previous_file_count = current_file_count
                    else:
                        print("⏳ Waiting for new coordinate data...")
                        
            except KeyboardInterrupt:
                print("\n👋 Coordinate monitor stopped")
                break
            except Exception as e:
                print(f"⚠️ Monitor error: {e}")
                time.sleep(5)  # Wait a bit before retrying
                
    except KeyboardInterrupt:
        print("\n👋 Coordinate monitor stopped")

def visualize_coordinate_differences():
    """Compare working vs API coordinates if both are available"""
    analyzer = CoordinateAnalyzer()
    
    # Look for reference files and regular coordinate files
    debug_dir = "debug_data"
    
    if not os.path.exists(debug_dir):
        print("❌ No debug_data directory found")
        return
    
    all_files = os.listdir(debug_dir)
    reference_files = [f for f in all_files if f.startswith('reference_') and f.endswith('.json')]
    coord_files = [f for f in all_files if f.startswith('coords_') and f.endswith('.json')]
    
    if reference_files and coord_files:
        print(f"📊 Comparing {len(reference_files)} reference files with {len(coord_files)} API files")
        
        # Get the most recent from each
        reference_files.sort(reverse=True)
        coord_files.sort(reverse=True)
        
        files_to_compare = [
            os.path.join(debug_dir, reference_files[0]),
            os.path.join(debug_dir, coord_files[0])
        ]
        
        print("🔍 Creating comparison visualization...")
        analyzer.visualize_2d(files_to_compare, "coordinate_comparison.png")
        
    elif reference_files:
        print("📄 Found reference files but no API coordinate files")
        print("💡 Send some coordinates to your API to generate comparison data")
    elif coord_files:
        print("📄 Found API coordinate files but no reference files")
        print("💡 Save reference coordinates from your working Python implementation")
    else:
        print("📭 No coordinate files found")
        print("💡 Generate some data first by:")
        print("   1. Running your working Python implementation and saving reference coordinates")
        print("   2. Sending coordinates to your API")

def create_video_from_api_coords(output_filename="api_coords_video.mp4", fps=5):
    """Create a video from all API coordinate files in the debug directory."""
    analyzer = CoordinateAnalyzer()
    debug_dir = "debug_data"
    
    if not os.path.exists(debug_dir):
        print(f"❌ Directory '{debug_dir}' not found.")
        return

    # Find and sort only the API coordinate files
    coord_files = sorted([f for f in os.listdir(debug_dir) if f.startswith('coords_') and f.endswith('.json')])
    
    if not coord_files:
        print("📭 No API coordinate files ('coords_*.json') found in 'debug_data' directory.")
        return

    print(f"🎬 Found {len(coord_files)} API coordinate files. Starting video creation...")

    # Use the first file to determine video dimensions
    try:
        first_file_path = os.path.join(debug_dir, coord_files[0])
        data = analyzer.load_coordinate_file(first_file_path)
        fig = analyzer.get_2d_plot_fig(data, f"Frame 1: {coord_files[0]}")
        
        fig.canvas.draw()
        img_buf = fig.canvas.tostring_rgb()
        img = np.frombuffer(img_buf, dtype=np.uint8).reshape(fig.canvas.get_width_height()[::-1] + (3,))
        height, width, _ = img.shape
        plt.close(fig)
    except Exception as e:
        print(f"❌ Could not process the first frame to get video dimensions: {e}")
        return

    # Initialize video writer
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video_writer = cv2.VideoWriter(output_filename, fourcc, fps, (width, height))

    for i, filename in enumerate(coord_files):
        print(f"  Processing frame {i+1}/{len(coord_files)}: {filename}")
        file_path = os.path.join(debug_dir, filename)
        
        try:
            data = analyzer.load_coordinate_file(file_path)
            fig = analyzer.get_2d_plot_fig(data, f"Frame {i+1}: {filename}")
            
            fig.canvas.draw()
            frame_img_buf = fig.canvas.tostring_rgb()
            frame_img = np.frombuffer(frame_img_buf, dtype=np.uint8).reshape(fig.canvas.get_width_height()[::-1] + (3,))
            frame_img_bgr = cv2.cvtColor(frame_img, cv2.COLOR_RGB2BGR) # OpenCV uses BGR format
            
            video_writer.write(frame_img_bgr)
            plt.close(fig)
        except Exception as e:
            print(f"    ⚠️ Could not process file {filename}: {e}")

    video_writer.release()
    print(f"\n✅ Video saved successfully as '{output_filename}'")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == "test":
            test_api_and_visualize()
        elif command == "monitor":
            live_coordinate_monitor()
        elif command == "compare":
            visualize_coordinate_differences()
        elif command == "video":
            create_video_from_api_coords()
        else:
            print("❓ Unknown command. Use: test, monitor, compare, or video")
    else:
        print("🎯 Coordinate Visualization Tool")
        print("=" * 40)
        print("Commands:")
        print("  python visualize_coords.py test     - Test API and show latest coordinates")
        print("  python visualize_coords.py monitor  - Monitor coordinates in real-time")
        print("  python visualize_coords.py compare  - Compare reference vs API coordinates")
        print("  python visualize_coords.py video    - Create a video from API coordinate files")
        print()
        print("Quick test:")
        test_api_and_visualize()
        create_video_from_api_coords()
