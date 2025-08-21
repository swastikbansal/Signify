import warnings
warnings.filterwarnings("ignore")

from flask import Flask, request, jsonify
import pickle
import numpy as np
from utils import Utils
from matplotlib import pyplot as plt
import mediapipe as mp
import cv2
import threading
from queue import Queue
import warnings

warnings.filterwarnings("ignore")


# Rest detection parameters (tweak these for your camera/subject)
REST_SPEED_THRESHOLD :float = 90.0   # pixels/second; lower => more sensitive to rest
MIN_POINTS_FOR_REST :int = 2       
REQUIRED_CONSECUTIVE_FRAMES :int = 3  



app = Flask(__name__)

# Queue for video frames to be displayed
frame_queue = Queue(maxsize=10)

# Global variables for frame accumulation
accumulated_probs = None
frame_count:int = 0


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

# Initialize MediaPipe solutions
mp_hands = mp.solutions.hands
mp_pose = mp.solutions.pose
hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.5, min_tracking_confidence=0.5)
pose = mp_pose.Pose(min_detection_confidence=0.7, min_tracking_confidence=0.7)

# Initialize Utils with axes for palm orientation
axes: dict = {
        "x": np.array([1, 0, 0]),
        "-x": np.array([-1, 0, 0]),
        "y": np.array([0, 1, 0]),
        "-y": np.array([0, -1, 0]),
        "z": np.array([0, 0, 1]),
        "-z": np.array([0, 0, -1]),
    }  
    
utils = Utils(axes, REST_SPEED_THRESHOLD, MIN_POINTS_FOR_REST, REQUIRED_CONSECUTIVE_FRAMES)

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

def process_image(img):
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
    
    # Trying to detect rest using the function
    try:
        resting = utils.is_resting(res_hands, annotated.shape)
        print(resting)
        if not resting:
            try:
                # Process hand landmarks (for both left and right hands)
                if res_hands.multi_hand_landmarks:
                    for hand_landmarks, handedness in zip(res_hands.multi_hand_landmarks, res_hands.multi_handedness):
                        label = handedness.classification[0].label
                        features = utils.extract_features(hand_landmarks.landmark, res_pose.pose_landmarks.landmark if res_pose.pose_landmarks else [])

                        if label == 'Left':
                            left_prediction = left_model.predict([features])[0]
                            left_probs = left_model.predict_proba([features])[0]
                        elif label == 'Right':
                            right_prediction = right_model.predict([features])[0]
                            right_probs = right_model.predict_proba([features])[0]

                        # Draw hand landmarks on the frame
                        mp.solutions.drawing_utils.draw_landmarks(
                            img, hand_landmarks, mp_hands.HAND_CONNECTIONS
                        )

                # Process pose landmarks
                if res_pose.pose_landmarks:
                    pose_landmarks = res_pose.pose_landmarks
                    pose_features = utils.extract_pose_features(pose_landmarks.landmark)  # Pass landmark attribute
                    pose_prediction = pose_model.predict([pose_features])[0]
                    pose_probs = pose_model.predict_proba([pose_features])[0]
                    
                    # Draw pose landmarks on the frame
                    mp.solutions.drawing_utils.draw_landmarks(
                        img, pose_landmarks, mp_pose.POSE_CONNECTIONS
                    )
            
            except Exception as e:
                print(f"Feature extraction error: {e}")
                return {"message": "Feature extraction failed", "frame_count": frame_count}, img

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
            if frame_count == 5:
                max_idx = np.argmax(accumulated_probs)
                pred = all_classes[max_idx]
                accumulated_probs = None
                frame_count = 0

            return {"prediction": pred} if pred else {"message": "Collecting frames", "frame_count": frame_count}, img
        else:
            return {"prediction": "rest"}
    except Exception as e:
        return {"message": "Error occurred", "error": str(e)}

@app.route('/')
def home():
    return "<h1>Signify API</h1>"

@app.route('/process_frame', methods=['POST'])
def process_video_frame():
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
            except Queue.Empty:
                pass  
            
        # Process the image to get a prediction
        result, annotated_img = process_image(img)
        
        if result.get("prediction"):
            # Clear the queue as we have a final prediction
            while not frame_queue.empty():
                try:
                    frame_queue.get_nowait()
                except Queue.Empty:
                    break
            
            text = f"Prediction: {result['prediction']}"
            cv2.putText(annotated_img, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)
            frame_queue.put(annotated_img)

            return jsonify({
                "status": "success",
                "prediction": result["prediction"]
            }), 200
        else:
            text = f"{result.get('message', 'Processing')} ({result.get('frame_count', 0)}/5)"
            cv2.putText(annotated_img, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)
            frame_queue.put(annotated_img)

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

if __name__ == '__main__':
    # Start the display thread
    display_thread = threading.Thread(target=display_frames)
    display_thread.daemon = True
    display_thread.start()

    print("Starting prediction API server...")
    print("Endpoints available:")
    print("- POST /process_frame - Process received frame and return predictions")
    print("- POST /reset - Reset frame accumulation")
    print("- GET /health - Health check")
    print("Press 'q' in the 'Live Stream' window to quit.")
    
    # use_reloader=False is important for threads
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)

