import mediapipe as mp
import cv2
import requests
from urllib.parse import urlparse
from pathlib import Path
import json
import numpy as np



mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.5, min_tracking_confidence=0.5)
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)

cap = cv2.VideoCapture(1)


if not cap.isOpened():
    print("Error: Could not open camera")
    exit()

print("Camera opened successfully. Press 'q' to quit.")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Error: Could not read frame")
        break

    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    results_hands = hands.process(image_rgb)
    results_pose = pose.process(image_rgb)
    
    # Draw landmarks
    if results_hands.multi_hand_landmarks:
        for hand_landmarks in results_hands.multi_hand_landmarks:
            mp.solutions.drawing_utils.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)    
    if results_pose.pose_landmarks:
        mp.solutions.drawing_utils.draw_landmarks(frame, results_pose.pose_landmarks, mp_pose.POSE_CONNECTIONS)

    # Prepare API data with raw coordinates only (send only when data is available)
    left_hand_coords = None
    right_hand_coords = None
    pose_coords = None
    
    # Extract hand coordinates more efficiently
    if results_hands.multi_hand_landmarks and results_hands.multi_handedness:
        for hand_landmarks, handedness in zip(results_hands.multi_hand_landmarks, results_hands.multi_handedness):
            hand_label = handedness.classification[0].label
            # More efficient coordinate extraction
            coords = [[lm.x, lm.y, lm.z] for lm in hand_landmarks.landmark]
            # Flatten the list
            coords_flat = [coord for point in coords for coord in point]
            
            if hand_label == "Left":
                left_hand_coords = coords_flat
            else:
                right_hand_coords = coords_flat

    # Extract pose coordinates
    if results_pose.pose_landmarks:
        pose_coords = [[lm.x, lm.y, lm.z] for lm in results_pose.pose_landmarks.landmark]
        pose_coords = [coord for point in pose_coords for coord in point]


    # Initialize prediction text
    prediction_text = "No prediction"
    status_text = "Waiting for data..."
    
    # Only send data if we have at least one type of landmarks
    if any([left_hand_coords, right_hand_coords, pose_coords]):
        api_data = {
            "left_hand": left_hand_coords,
            "right_hand": right_hand_coords,
            "pose": pose_coords
        }
        
        
        # Send data to API
        try:
            response = requests.post("http://192.168.29.42:5000/predict", 
                                   json=api_data, 
                                   timeout=0.1)
            
            if response.status_code == 200:
                result = response.json()
                
                if result.get('prediction'):
                    prediction_text = result['prediction']
                    status_text = "Prediction ready"
                    print(f"Prediction: {result['prediction']}")
                elif result.get('status') == 'collecting':
                    status_text = f"Collecting frames: {result.get('frame_count', 0)}/5"
                else:
                    status_text = "Processing..."
                        
        except requests.exceptions.RequestException:
            status_text = "API unavailable"
    
    # Display prediction and status on frame
    cv2.putText(frame, f"Prediction: {prediction_text}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
    cv2.putText(frame, f"Status: {status_text}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
    cv2.putText(frame, "Press 'q' to quit", (10, frame.shape[0] - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
    
    # Display the frame
    cv2.imshow('Hand Detection', frame)
    
    # Check for 'q' key press to quit
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break


# Cleanup
cap.release()
cv2.destroyAllWindows()