from flask import Flask, request, jsonify
import requests
import os
from urllib.parse import urlparse
from werkzeug.utils import secure_filename
import mediapipe as mp
import cv2
import mediapipe as mp

# import google.generativeai as genai

import pickle
from glob import glob
from pathlib import Path

from numpy import  argmax, expand_dims 
import numpy as np

from Direct_python_version.utils import Utils
from flask import Flask, request, jsonify
import json
import threading
import time
from queue import Queue

app = Flask(__name__)

# Queue to store incoming landmark data
landmark_queue = Queue(maxsize=100)

class LandmarkProcessor:
    def __init__(self):
        self.latest_data = None
        self.processing_thread = threading.Thread(target=self.process_landmarks, daemon=True)
        self.processing_thread.start()
    
    def process_landmarks(self):
        """Process landmarks in a separate thread"""
        while True:
            try:
                if not landmark_queue.empty():
                    data = landmark_queue.get(timeout=1)
                    self.latest_data = data
                    
                    # Process the landmark data
                    self.analyze_gestures(data)
                    
                time.sleep(0.01)  # Small delay to prevent excessive CPU usage
            except Exception as e:
                print(f"Processing error: {e}")
    
    def analyze_gestures(self, data):
        """Analyze gestures from landmark data"""
        if data.get('left_hand'):
            print("Left hand detected")
            # Add your gesture recognition logic here
            
        if data.get('right_hand'):
            print("Right hand detected")
            # Add your gesture recognition logic here
            
        if data.get('pose'):
            print("Pose detected")
            # Add your pose analysis logic here

# Initialize processor
processor = LandmarkProcessor()

def process_video(results):
    left_model_filename = r'Models\left.p'
    right_model_filename = r'Models\right.p'
    pose_model_filename = r'Models\pose.p'
    
    with open(left_model_filename, 'rb') as f:
        left_model_data = pickle.load(f)
        left_model = left_model_data['model']  # Adjust if the key for the model is different

    with open(right_model_filename, 'rb') as f:
        right_model_data = pickle.load(f)
        right_model = right_model_data['model']  # Adjust if the key for the model is different

    with open(pose_model_filename, 'rb') as f:
        pose_model_data = pickle.load(f)
        pose_model = pose_model_data['model']  # Adjust if the key for the model is different
    
    axes = {
        "x": np.array([1, 0, 0]),
        "-x": np.array([-1, 0, 0]),
        "y": np.array([0, 1, 0]),
        "-y": np.array([0, -1, 0]),
        "z": np.array([0, 0, 1]),
        "-z": np.array([0, 0, -1]),
    }  
    
    utils = Utils(axes)
    
    
    # mp_hands = mp.solutions.hands
    # mp_pose = mp.solutions.pose

    # hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.7, min_tracking_confidence=0.7)
    # pose = mp_pose.Pose(min_detection_confidence=0.7, min_tracking_confidence=0.7)
    
    #10 frames
    def calulating_percentage(avg, all_classes):
        individual_threshold = {
            'clean': 0.3, 'happy': 0.32, 'high': 0.55, 'loud': 0.80, 'quiet': 0.9,
            'sad': 0.6, 'deep': 0.5, 'soft': 0.5, 'weak': 0.6, 'flat': 0.30,
            'expensive': 0.27, 'poot': 0.35, 'slow': 0.6, 'thick': 0.7
        }
        
        threshold_percentage = []
        for i, j in zip(avg, all_classes):
            value = individual_threshold[j.lower()]
            threshold_percentage.append(i * 100 / value)
        return threshold_percentage

    # cap = cv2.VideoCapture(video_path)

    # Create a dictionary to accumulate the probabilities for 10 frames
    # frame_count = 0
    accumulated_probs = None
    final_prediction = []
    # n_frames = cap.get(cv2.CAP_PROP_FRAME_COUNT)

    # for i in range(int(n_frames)):
    #     ret, frame = cap.read()
    #     if not ret:
    #         break

    #     # Convert the frame to RGB for MediaPipe processing
    #     image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    #     results = hands.process(image_rgb)
    #     results_pose = pose.process(image_rgb)

    #     # Initialize predictions and probabilities
    #     left_prediction, right_prediction, pose_prediction = None, None, None
    #     left_probs, right_probs, pose_probs = None, None, None
    #     left_normal_direction = -1
        # Process hand landmarks (for both left and right hands)
    if results.multi_hand_landmarks:
        for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
            label = handedness.classification[0].label
            features = utils.extract_features(hand_landmarks.landmark, results_pose.pose_landmarks.landmark if results_pose.pose_landmarks else [])

            if label == 'Left':
                left_prediction = left_model.predict([features])[0]
                left_probs = left_model.predict_proba([features])[0]
            elif label == 'Right':
                right_prediction = right_model.predict([features])[0]
                right_probs = right_model.predict_proba([features])[0]

    # Process pose landmarks
    if results_pose.pose_landmarks:
        pose_landmarks = results_pose.pose_landmarks.landmark
        pose_features = utils.extract_pose_features(frame, pose_landmarks)  # Pass both frame and pose_landmarks
        pose_prediction = pose_model.predict([pose_features])[0]
        pose_probs = pose_model.predict_proba([pose_features])[0]

    # Initialize the combined prediction logic
    if left_prediction is not None and right_prediction is not None and pose_prediction is not None:
        # All three detected, combine their probabilities
        all_classes = sorted(set(left_model.classes_).union(set(right_model.classes_)).union(set(pose_model.classes_)))

        # Align probabilities with all possible classes
        left_prob_dict = {cls: prob for cls, prob in zip(left_model.classes_, left_probs)}
        right_prob_dict = {cls: prob for cls, prob in zip(right_model.classes_, right_probs)}
        pose_prob_dict = {cls: prob for cls, prob in zip(pose_model.classes_, pose_probs)}

        left_probs_aligned = np.array([left_prob_dict.get(cls, 0) for cls in all_classes]) * 100
        right_probs_aligned = np.array([right_prob_dict.get(cls, 0) for cls in all_classes]) * 100
        pose_probs_aligned = np.array([pose_prob_dict.get(cls, 0) for cls in all_classes]) * 100

        # Compute average probabilities
        avg = (left_probs_aligned + right_probs_aligned + pose_probs_aligned) / 300
        avg_probs = calulating_percentage(avg, all_classes)

        # If accumulated_probs is None, initialize it
        if accumulated_probs is None:
            accumulated_probs = np.zeros_like(avg_probs)

        # Accumulate the probabilities over 10 frames
        accumulated_probs += avg_probs
        frame_count += 1

        if frame_count == 10:
            # After 10 frames, find the class with the highest accumulated probability
            max_prob_index = np.argmax(accumulated_probs)
            max_prob_class = all_classes[max_prob_index]
            
            # Store the final prediction text
            final_prediction.append(accumulated_probs[max_prob_index])

            # Reset accumulated_probs for the next cycle
            accumulated_probs = None
            frame_count = 0


    # Release the capture object
    cap.release()

    return final_prediction

@app.route('/')
def home():
    return 'API is working'

@app.route('/predict', methods=['GET','POST'])
def predict_video():
    data = request.get_json()
    
    if not data or 'link' not in data:
        return jsonify({'error': 'No link provided'}), 400
    
    link = data['link']
    print(link)
    
    try:
        # Get the video content
        response = requests.get(link, stream=True)
        response.raise_for_status()
        
        os.makedirs('downloads', exist_ok=True)
        
        # Extract the video filename from the link
        parsed_url = urlparse(link)
        filename = os.path.basename(parsed_url.path)
        filename = f"downloads\{secure_filename(filename)}"
        
        if filename not in glob('downloads\*'):           
            # Save the video locally
            with open(filename, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            print(f"{filename} saved")
        
        else:
            print(f"{filename} already exists")
        
        # Process the video
        prediction = process_video(filename)
        
        print(prediction)
        
        # genai.configure(api_key="AIzaSyBwC9kfjLF_qvb004UsCZIt6ho-XuzPWrg")

        # model = genai.GenerativeModel(model_name="gemini-1.5-flash")
        # response = model.generate_content(f"Genarte an meaningful setence from the list of prediction: {prediction} of a INDIAN Sign Language prediction model. Do not specifuy thats it is a INDIAN Sign Language prediction model just give the sentence.") 
        # print(response.text)
        
        
        # return jsonify({'sentence': response.text, 'prediction':prediction}), 200
        return jsonify({'prediction':prediction}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    

@app.route('/process_landmarks', methods=['POST'])
def receive_landmarks():
    """Receive landmark data from test.py"""
    try:
        data = request.get_json()
        
        if data:
            # Add to queue for processing
            if not landmark_queue.full():
                landmark_queue.put(data)
            else:
                # Remove oldest item if queue is full
                try:
                    landmark_queue.get_nowait()
                    landmark_queue.put(data)
                except:
                    pass
        
        return jsonify({"status": "success", "message": "Data received"}), 200
    
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 400

@app.route('/get_latest_data', methods=['GET'])
def get_latest_data():
    """Get the latest processed landmark data"""
    if processor.latest_data:
        return jsonify(processor.latest_data), 200
    else:
        return jsonify({"message": "No data available"}), 204

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "queue_size": landmark_queue.qsize()}), 200

if __name__ == '__main__':    
    # Load pre-trained models from pick-le files
    
    print("Starting landmark processing API server...")
    print("Endpoints available:")
    print("- POST /process_landmarks - Receive landmark data")
    print("- GET /get_latest_data - Get latest processed data")
    print("- GET /health - Health check")
    
    app.run(host='127.0.0.1', port=5000, debug=True, threaded=True)
