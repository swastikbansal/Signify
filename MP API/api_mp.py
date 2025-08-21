import warnings
warnings.filterwarnings("ignore")

from flask import Flask, request, jsonify
import pickle
import numpy as np
from utils_mpAPI import Utils
from matplotlib import pyplot as plt
import os 
import json
import datetime
import time

app = Flask(__name__)

# Global variables for frame accumulation
accumulated_probs = None
frame_count = 0

# Directory for debug data
DEBUG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "debug_data")
os.makedirs(DEBUG_DIR, exist_ok=True)

# Enable/disable debug mode
DEBUG_MODE = False

def analyze_coordinate_stats(coords, coord_type):
    """Analyze coordinate statistics for debugging"""
    if not coords:
        return None
    
    try:
        flat_coords = np.array([val for point in coords for val in point if isinstance(val, (int, float))])
        x_coords = [p[0] for p in coords if isinstance(p, list) and len(p) >= 3]
        y_coords = [p[1] for p in coords if isinstance(p, list) and len(p) >= 3]
        z_coords = [p[2] for p in coords if isinstance(p, list) and len(p) >= 3]
        
        stats = {
            "count": len(coords),
            "dimensions": len(coords[0]) if coords and isinstance(coords[0], list) else 0,
            "overall": {
                "min": float(np.min(flat_coords)),
                "max": float(np.max(flat_coords)),
                "mean": float(np.mean(flat_coords)),
                "std": float(np.std(flat_coords))
            },
            "x": {
                "min": float(np.min(x_coords)) if x_coords else None,
                "max": float(np.max(x_coords)) if x_coords else None,
                "mean": float(np.mean(x_coords)) if x_coords else None
            },
            "y": {
                "min": float(np.min(y_coords)) if y_coords else None,
                "max": float(np.max(y_coords)) if y_coords else None,
                "mean": float(np.mean(y_coords)) if y_coords else None
            },
            "z": {
                "min": float(np.min(z_coords)) if z_coords else None,
                "max": float(np.max(z_coords)) if z_coords else None,
                "mean": float(np.mean(z_coords)) if z_coords else None
            }
        }
        return stats
    except Exception as e:
        return {"error": str(e)}

def save_debug_data(left_coords, right_coords, pose_coords, prediction=None):
    """Save coordinate data to file for debugging"""
    if not DEBUG_MODE:
        return
    
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    
    # Get coordinate statistics
    stats = {}
    if left_coords:
        stats["left_hand"] = analyze_coordinate_stats(left_coords, "left_hand")
    if right_coords:
        stats["right_hand"] = analyze_coordinate_stats(right_coords, "right_hand")
    if pose_coords:
        stats["pose"] = analyze_coordinate_stats(pose_coords, "pose")
    
    data = {
        "timestamp": timestamp,
        "left_hand": left_coords,
        "right_hand": right_coords,
        "pose": pose_coords,
        "prediction": prediction,
        "statistics": stats
    }
    
    filename = os.path.join(DEBUG_DIR, f"coords_{timestamp}.json")
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    
    return filename

def visualize_coordinates(left_coords, right_coords, pose_coords, filename=None):
    """Generate a visualization of the coordinates"""
    if not DEBUG_MODE:
        return None
        
    fig = plt.figure(figsize=(15, 7))
    
    # Plot left hand
    if left_coords:
        ax1 = fig.add_subplot(131, projection='3d')
        x = [p[0] for p in left_coords]
        y = [p[1] for p in left_coords]
        z = [p[2] for p in left_coords]
        ax1.scatter(x, y, z, c='r')
        ax1.set_title('Left Hand')
        ax1.set_xlabel('X')
        ax1.set_ylabel('Y')
        ax1.set_zlabel('Z')
    
    # Plot right hand
    if right_coords:
        ax2 = fig.add_subplot(132, projection='3d')
        x = [p[0] for p in right_coords]
        y = [p[1] for p in right_coords]
        z = [p[2] for p in right_coords]
        ax2.scatter(x, y, z, c='b')
        ax2.set_title('Right Hand')
        ax2.set_xlabel('X')
        ax2.set_ylabel('Y')
        ax2.set_zlabel('Z')
    
    # Plot pose
    if pose_coords:
        ax3 = fig.add_subplot(133, projection='3d')
        x = [p[0] for p in pose_coords]
        y = [p[1] for p in pose_coords]
        z = [p[2] for p in pose_coords]
        ax3.scatter(x, y, z, c='g')
        ax3.set_title('Pose')
        ax3.set_xlabel('X')
        ax3.set_ylabel('Y')
        ax3.set_zlabel('Z')
    
    plt.tight_layout()
    
    if filename:
        plt.savefig(filename)
        plt.close()
        return filename
    
    return fig

def calulating_percentage(avg, all_classes):
    """
    Given a list of average probabilities (avg) and corresponding class labels (all_classes),
    returns a list of percentage values adjusted by class-specific thresholds.
    """
    
    individual_threshold = {
        "sun": 0.9, "help": 0.9, "teacher": 0.9, "support": 0.9,
        "paper": 0.9, "love": 0.9, "dance": 0.9, "water": 0.9,
        "accident": 0.9, "yes": 0.9, "thick": 0.9, "high": 0.9,
        "poor": 0.9, "i": 0.9, "my": 0.9, "important_1": 0.9,
        "important_2": 0.9, "deaf": 0.9, "winner": 0.9, "eat": 0.9,
        "pizza": 0.9, "go": 0.9, "isl": 0.9, "friend": 0.9,
        "school": 0.9, "deep": 0.9, "loud": 0.9, "flat": 0.9,
        "slow": 0.9, "sad": 0.9, "soft": 0.9, "happy": 0.9,
        "poot": 0.9, "quiet": 0.9, "book": 0.9, "woman": 0.9
    }

    threshold_percentage = []
    for score, cls in zip(avg, all_classes):
        threshold_val = individual_threshold.get(cls.lower(), 1.0)
        threshold_percentage.append(score * 100 / threshold_val)

    return threshold_percentage

def load_models():
    """Load all models"""
    left_model_filename = r'Models\left_model.p'
    right_model_filename = r'Models\right_model.p'
    pose_model_filename = r'Models\pose_model.p'

    def load_model(filename):
        with open(filename, 'rb') as f:
            model_data = pickle.load(f)
            return model_data['model']

    return (load_model(left_model_filename), 
            load_model(right_model_filename), 
            load_model(pose_model_filename))

# Load models once at startup
left_model, right_model, pose_model = load_models()

# Initialize Utils with axes for palm orientation
axes = {
    'x': np.array([1, 0, 0]),
    'y': np.array([0, 1, 0]),
    'z': np.array([0, 0, 1])
}
utils = Utils(axes)

def process_frame(left_coords, right_coords, pose_coords):
    """Process a single frame of coordinate data"""
    global accumulated_probs, frame_count
    
    
        
    # Original processing logic
    pred = None
    left_probs, right_probs, pose_probs = None, None, None
    
    try:
        # Process left hand
        if left_coords:
            left_features = utils.extract_features(left_coords, pose_coords)
            left_probs = left_model.predict_proba([left_features])[0]
        
        # Process right hand
        if right_coords:
            right_features = utils.extract_features(right_coords, pose_coords)
            right_probs = right_model.predict_proba([right_features])[0]

        # Process pose
        if pose_coords:
            pose_features = utils.extract_pose_features(pose_coords)
            pose_probs = pose_model.predict_proba([pose_features])[0]
    
    except Exception as e:
        print(f"Feature extraction error: {e}")
        return {"message": "Feature extraction failed", "frame_count": frame_count}

    # Gathering all class labels used by the three models
    all_classes = sorted(
        set(left_model.classes_).union(
        set(right_model.classes_)).union(
        set(pose_model.classes_))
    )
    
    # Aligning probabilities with the master list of classes
    left_probs_aligned = np.zeros(len(all_classes))
    right_probs_aligned = np.zeros(len(all_classes))
    pose_probs_aligned = np.zeros(len(all_classes))
    
    if left_probs is not None:
        left_dict = dict(zip(left_model.classes_, left_probs))
        left_probs_aligned = np.array([left_dict.get(cls, 0) for cls in all_classes]) * 100

    if right_probs is not None:
        right_dict = dict(zip(right_model.classes_, right_probs))
        right_probs_aligned = np.array([right_dict.get(cls, 0) for cls in all_classes]) * 100

    if pose_probs is not None:
        pose_dict = dict(zip(pose_model.classes_, pose_probs))
        pose_probs_aligned = np.array([pose_dict.get(cls, 0) for cls in all_classes]) * 100
  
    # Determine the number of available sources (hand(s)/pose)
    num_sources = sum(prob is not None for prob in [left_probs, right_probs, pose_probs])
    if num_sources == 0:
        return {"message": "No valid data", "frame_count": frame_count}
        
    avg = (left_probs_aligned + right_probs_aligned + pose_probs_aligned) / (100 * num_sources)

    # Convert these averages into final percentages based on custom thresholds
    avg_probs = calulating_percentage(avg, all_classes)

    if accumulated_probs is None:
        accumulated_probs = np.zeros_like(avg_probs)
    accumulated_probs += avg_probs
    frame_count += 1
    
    # Updating the final prediction text after a fixed no. of frames
    if frame_count == 10:
        max_idx = np.argmax(accumulated_probs)
        pred = all_classes[max_idx]
        accumulated_probs = None
        frame_count = 0

    

    return {"prediction": pred} if pred else {"message": "Collecting frames", "frame_count": frame_count}

@app.route('/predict', methods=['POST'])
def predict():
    """Receive coordinates and return prediction"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"status": "error", "message": "No data received"}), 400
        
        # Extract coordinates from the request
        left_coords = data.get('left_hand')
        right_coords = data.get('right_hand')
        pose_coords = data.get('pose')
        
        # Save debug data if debug mode is enabled
        debug_file = save_debug_data(left_coords, right_coords, pose_coords)
        
        # Validate that at least one type of data is present
        if not any([left_coords, right_coords, pose_coords]):
            return jsonify({"status": "error", "message": "No valid coordinate data received"}), 400
        
        # Process the frame
        result = process_frame(left_coords, right_coords, pose_coords)

        # If in debug mode and we have a prediction, save a visualization
        if DEBUG_MODE and result.get("prediction"):
            vis_filename = os.path.splitext(debug_file)[0] + ".png" if debug_file else None
            visualize_coordinates(left_coords, right_coords, pose_coords, vis_filename)
            # Update the debug file with prediction
            save_debug_data(left_coords, right_coords, pose_coords, result.get("prediction"))

        if result.get("prediction"):
            print("prediction:", result["prediction"])
            return jsonify({
                "status": "success",
                "prediction": result["prediction"]
            }), 200
        else:
            return jsonify({
                "status": "collecting",
                "message": result.get("message", "Processing frames"),
                "frame_count": result.get("frame_count", 0)
            }), 200
    
    except Exception as e:
        return jsonify({"status": "error", "message": f"Processing error: {str(e)}"}), 500

@app.route('/reset', methods=['POST'])
def reset_accumulation():
    """Reset the frame accumulation"""
    global accumulated_probs, frame_count
    accumulated_probs = None
    frame_count = 0
    return jsonify({"status": "success", "message": "Accumulation reset"}), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy", 
        "frame_count": frame_count,
        "models_loaded": True
    }), 200

@app.route('/debug/toggle', methods=['POST'])
def toggle_debug():
    """Toggle debug mode"""
    global DEBUG_MODE
    DEBUG_MODE = not DEBUG_MODE
    return jsonify({
        "status": "success",
        "debug_mode": DEBUG_MODE,
        "debug_dir": DEBUG_DIR
    }), 200

if __name__ == '__main__':
    print("Starting prediction API server...")
    print("Endpoints available:")
    print("- POST /predict - Send coordinates and get prediction")
    print("- POST /reset - Reset frame accumulation")
    print("- GET /health - Health check")
    print("- POST /debug/toggle - Toggle debug mode")
    
    print(f"Debug directory: {DEBUG_DIR}")
    
    app.run(host='192.168.29.42', port=5000, debug=False, threaded=True)

