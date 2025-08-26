#API
from flask import Flask, request, jsonify

# ML
import pickle
import numpy as np
from matplotlib import pyplot as plt
import mediapipe as mp
import cv2

# System modules
import threading
from queue import Queue, Empty
import warnings
import os
import warnings
warnings.filterwarnings("ignore")

#Custom modules
from utils import Utils
from CustomTrainer import Trainer

# TO DO
# Switching the model based on the response received from the model


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

def load_models(model_type:str = "Default"):
    if model_type == "Default":
        """Load all models"""
        left_model_filename = r'./Models/left_model.p'
        right_model_filename = r'./Models/right_model.p'
        pose_model_filename = r'./Models/pose_model.p'

    elif model_type == "Custom":
        left_model_filename = r'./Custom_Dataset/Models/left_model_new.p'
        right_model_filename = r'./Custom_Dataset/Models/right_model_new.p'
        pose_model_filename = r'./Custom_Dataset/Models/pose_model_new.p'

    def load_model(filename):
        with open(filename, 'rb') as f:
            model_data = pickle.load(f)
            return model_data['model']

    return (load_model(left_model_filename), 
            load_model(right_model_filename), 
            load_model(pose_model_filename))

def display_frames():
    """
    This function runs in a separate thread.
    It continuously gets frames from a queue and displays them.
    """
    while True:
        try:
            img = frame_queue.get()
            if img is None:
                break
            
            cv2.imshow("Live Stream", img)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        except Exception as e:
            print(f"Error in display thread: {e}")
            break
    cv2.destroyAllWindows()

def process_image(img, USE_REST:bool = False):
    """Process a single image (np.array) to get a prediction."""
    global accumulated_probs, frame_count

    pred = None
    left_probs, right_probs, pose_probs = None, None, None

    img.flags.writeable = False
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    res_pose = pose.process(img_rgb)
    res_hands = hands.process(img_rgb)
    img.flags.writeable = True
    annotated = img.copy()
    

    try:
        if USE_REST:
            resting = utils.is_resting(res_hands, annotated.shape, rest_delay_seconds=REST_DELAY, fps=None)
        else:
            resting = False
    except Exception as e:
        print(f"Rest detection error: {e}")
        resting = False

    if resting:
        return {"prediction": "rest"}, annotated

    try:
        if getattr(res_hands, "multi_hand_landmarks", None):
            for hand_landmarks, handedness in zip(res_hands.multi_hand_landmarks, res_hands.multi_handedness):
                label = handedness.classification[0].label
                features = utils.extract_hand_features(
                    hand_landmarks.landmark,
                    res_pose.pose_landmarks.landmark if res_pose.pose_landmarks else []
                )

                if label == 'Left':
                    left_probs = left_model.predict_proba([features])[0]
                elif label == 'Right':
                    right_probs = right_model.predict_proba([features])[0]

                # Draw hand landmarks on the frame
                mp.solutions.drawing_utils.draw_landmarks(
                    img, hand_landmarks, mp.solutions.hands.HAND_CONNECTIONS
                )

        if getattr(res_pose, "pose_landmarks", None):
            pose_landmarks = res_pose.pose_landmarks
            pose_features = utils.extract_pose_features(pose_landmarks.landmark)
            pose_prediction = pose_model.predict([pose_features])[0]
            pose_probs = pose_model.predict_proba([pose_features])[0]
            # Draw pose landmarks on the frame
            mp.solutions.drawing_utils.draw_landmarks(
                img, pose_landmarks, mp_pose.POSE_CONNECTIONS
            )

    except Exception as e:
        print(f"Feature extraction error: {e}")
        return {"message": "Feature extraction failed", "frame_count": frame_count}, annotated

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
        return {"message": "No valid data", "frame_count": frame_count}, annotated

    avg = (left_probs_aligned + right_probs_aligned + pose_probs_aligned) / (100 * num_sources)

    # Convert these averages into final percentages based on custom thresholds
    avg_probs = calulating_percentage(avg, all_classes)

    if accumulated_probs is None:
        accumulated_probs = np.zeros_like(avg_probs)
    accumulated_probs += avg_probs
    frame_count += 1

    # Updating the final prediction text after a fixed no. of frames
    if frame_count == 5:
        max_idx = np.argmax(accumulated_probs)
        pred = all_classes[max_idx]
        accumulated_probs = None
        frame_count = 0

    return ({"prediction": pred} if pred else {"message": "Collecting frames", "frame_count": frame_count}), annotated

# Rest detection parameters
REST_SPEED_THRESHOLD :float = 30.0   # pixels/second; lower => more sensitive to rest
MIN_POINTS_FOR_REST :int = 2       
REQUIRED_CONSECUTIVE_FRAMES :int = 3  
REST_DELAY = 2
USE_REST: bool = False

app = Flask(__name__)

# Queue for video frames to be displayed
frame_queue = Queue(maxsize=10)

# Global variables for frame accumulation
accumulated_probs = None
frame_count:int = 0
model_type = "Custom"   

# Load models once at startup
left_model, right_model, pose_model = load_models()

# Initialize MediaPipe solutions
mp_hands = mp.solutions.hands
mp_pose = mp.solutions.pose
hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.5, min_tracking_confidence=0.5)
pose = mp_pose.Pose(min_detection_confidence=0.7, min_tracking_confidence=0.7)

utils = Utils(REST_SPEED_THRESHOLD, MIN_POINTS_FOR_REST, REQUIRED_CONSECUTIVE_FRAMES)
trainer = Trainer(hands,pose)

@app.route('/')
def home():
    return "<h1>Signify API</h1>"

@app.route('/customTrain', methods= ['GET',"POST"])
def custom_model():
    try:
        status = trainer.run_training()
        if status:
            print("Model training completed")
            switch_model_internal("Custom")
            return jsonify({"status": "success", "message": "Custom model training completed and switched"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": f"Error training model: {str(e)}"}), 500


@app.route('/switchModel', methods=['POST', 'GET'])
def switch_model():
    """Switch the model based on the response received from the model."""
    try:
        data = request.json
        model_type = data.get('model', 'Default')
        switch_model_internal(model_type)
        return jsonify({"status": "success", "message": f"Switched to model type {model_type}"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": f"Error switching model: {str(e)}"}), 500

def switch_model_internal(model_type: str):
    """Internal function to switch models"""
    global left_model, right_model, pose_model
    left_model, right_model, pose_model = load_models(model_type)
    print(f"Models switched to: {model_type}")

@app.route('/processFrame', methods=['POST'])
def process_frame():
    """Receive a video frame, display it, and return a prediction."""
    try:
        if 'frame' not in request.files:
            return jsonify({"status": "error", "message": "No frame file received"}), 400
        
        file = request.files['frame']
        img_data = file.read()
        
        np_arr = np.frombuffer(img_data, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        
        if img is None:
            return jsonify({"status": "error", "message": "Failed to decode image"}), 400
        
        # Rotate the frame 90 degrees clockwise
        img = cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
        
        if frame_queue.full():
            try:
                # Non-blocking get to remove the oldest frame
                frame_queue.get_nowait()
            except Empty:
                pass  
            
        # Process the image to get a prediction
        result, annotated_img = process_image(img)

        if result.get("USE_REST"):
            result, annotated_img = process_image(img, USE_REST=result["USE_REST"])

        if result.get("prediction"):
            # Clear the queue as we have a final prediction
            while not frame_queue.empty():
                try:
                    frame_queue.get_nowait()
                except Empty:
                    break
            
            text = f"Prediction: {result['prediction']}"
            cv2.putText(annotated_img, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)
            frame_queue.put(annotated_img)

            return jsonify({
                "status": "success",
                "prediction": result["prediction"]
            }, 200)
        else:
            text = f"{result.get('message', 'Processing')} ({result.get('frame_count', 0)}/5)"
            cv2.putText(annotated_img, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)
            frame_queue.put(annotated_img)

            return jsonify({
                "status": "collecting",
                "message": result.get("message", "Processing frames"),
                "frame_count": result.get("frame_count", 0)
            }, 200)

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

if __name__ == '__main__':
    # Start the display thread
    display_thread = threading.Thread(target=display_frames)
    display_thread.daemon = True
    display_thread.start()

    print("Starting prediction API server...")
    print("Endpoints available:")
    print("- POST /processFrame - Process received frame and return predictions")
    print("- GET, POST /customTrain - Train a custom model")
    print("- POST /switchModel - Switch between models")
    print("- POST /reset - Reset frame accumulation")
    print("- GET /health - Health check")
    print("Press 'q' in the 'Live Stream' window to quit.")
    
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)

