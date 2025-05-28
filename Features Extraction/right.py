import os
import cv2
import mediapipe as mp
import pickle
import numpy as np

# Initialize mediapipe hands and pose detectors
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.5, min_tracking_confidence=0.5)
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# Function to calculate the angle between two vectors
def calculate_angle(vec1, vec2):
    dot_product = np.dot(vec1, vec2)
    norm_vec1 = np.linalg.norm(vec1)
    norm_vec2 = np.linalg.norm(vec2)
    cosine_angle = dot_product / (norm_vec1 * norm_vec2)
    #angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return cosine_angle #np.degrees(angle)  # Convert the angle from radians to degrees

# Function to extract hand features (angles between vectors and axes)
def extract_hand_features(image, hand_landmarks, pose_landmarks=None):
    # Define the hand pairs (index of the landmarks as per mediapipe)
    hand_pairs = [
        (1, 3),  # Thumb
        (6, 8),  # Index finger
        (10, 12),  # Middle finger
        (14, 16),  # Ring finger
        (18, 20),  # Pinky finger
        (0, 9)  # Palm direction
    ]
    
    # Prepare to store the features
    features = []
    
    # Calculate vector and angles for each hand pair
    for pair in hand_pairs:
        # Extract the coordinates of the two landmarks
        landmark1 = hand_landmarks[pair[0]]
        landmark2 = hand_landmarks[pair[1]]
        
        # Create the vector between the two landmarks (subtract the coordinates)
        vector = np.array([landmark2.x - landmark1.x, landmark2.y - landmark1.y, landmark2.z - landmark1.z])
        
        # Define the unit vectors for the x, y, z axes
        x_axis = np.array([1, 0, 0])
        y_axis = np.array([0, 1, 0])
        z_axis = np.array([0, 0, 1])
        
        # Calculate the angles between the vector and each axis
        angle_x = calculate_angle(vector, x_axis)
        angle_y = calculate_angle(vector, y_axis)
        angle_z = calculate_angle(vector, z_axis)
        
        # Append the angles to the features list
        features.extend([angle_x, angle_y, angle_z])
    
    # Calculate the normal to the palm plane using landmarks 0, 5, and 17
    # Vector from 0 to 5
    vector_0_to_5 = np.array([
        hand_landmarks[5].x - hand_landmarks[0].x,
        hand_landmarks[5].y - hand_landmarks[0].y,
        hand_landmarks[5].z - hand_landmarks[0].z
    ])
    
    # Vector from 0 to 17
    vector_0_to_17 = np.array([  
        hand_landmarks[17].x - hand_landmarks[0].x,
        hand_landmarks[17].y - hand_landmarks[0].y,
        hand_landmarks[17].z - hand_landmarks[0].z
    ])
    
    # Cross product to find the normal vector
    normal_vector = np.cross(vector_0_to_5, vector_0_to_17)
    
    # Calculate the angles of the normal vector with respect to the x, y, and z axes
    normal_angle_x = calculate_angle(normal_vector, x_axis)
    normal_angle_y = calculate_angle(normal_vector, y_axis)
    normal_angle_z = calculate_angle(normal_vector, z_axis)
    
    # Append these angles as the new features
    features.extend([normal_angle_x, normal_angle_y, normal_angle_z])
    
    # If pose landmarks are available, calculate the distance in x and y axes between the nose and wrist
    if pose_landmarks:
        nose_landmark = pose_landmarks[0]  # Nose is at index 0 in pose landmarks
        wrist_landmark = hand_landmarks[0]  # Wrist is at index 0 in hand landmarks
        
        # Calculate the distance in the x and y axes
        distance_x = abs(nose_landmark.x - wrist_landmark.x)
        distance_y = abs(nose_landmark.y - wrist_landmark.y)
        
        # Append the x and y distances as new features
        features.extend([distance_x, distance_y])
    
    return features

# Path to your "data" folder
data_folder = './data'

data = []
labels = []

# Iterate through the classes folder
for label in os.listdir(data_folder):
    class_folder = os.path.join(data_folder, label)
    
    if os.path.isdir(class_folder):
        # Iterate through images in each class folder
        for image_name in os.listdir(class_folder):
            image_path = os.path.join(class_folder, image_name)
            
            # Read the image
            image = cv2.imread(image_path)
            
            # Convert image to RGB
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            results = hands.process(image_rgb)
            
            # Process pose landmarks
            image_pose_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            pose_results = pose.process(image_pose_rgb)
            
            # If hands are detected, extract features for the right hand
            if results.multi_hand_landmarks:
                for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
                    if handedness.classification[0].label == 'Right':  # Only process right hand
                        if pose_results.pose_landmarks:
                            features = extract_hand_features(image, hand_landmarks.landmark, pose_results.pose_landmarks.landmark)
                            data.append(features)
                            labels.append(label)  # Only save the class label (e.g., "1")

# Close the Mediapipe Hands and Pose processes
hands.close()
pose.close()

# Save the data and labels into a pickle file
output_file = 'right15.pkl'
with open(output_file, 'wb') as f:
    pickle.dump({'data': data, 'labels': labels}, f)

print(f"Pickle file saved at {output_file}")
