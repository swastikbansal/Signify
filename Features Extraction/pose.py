import os
import cv2
import numpy as np
import pickle
import mediapipe as mp

# Initialize MediaPipe pose module
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

# Function to extract the 3D coordinates from the landmark
# Function to safely extract the 3D coordinates from the landmark
def get_coordinates_safe(landmark, index):
    try:
        return np.array([landmark[index].x, landmark[index].y, landmark[index].z])
    except IndexError:
        return np.array([-1, -1, -1])  # Return default values (e.g., [-1, -1, -1]) if landmark is not found
    

def calculate_normal_safe(p1, p2, p3):
    # Check if any of the points is [-1, -1, -1] (default value for missing landmarks)
    if np.array_equal(p1, [-1, -1, -1]) or np.array_equal(p2, [-1, -1, -1]) or np.array_equal(p3, [-1, -1, -1]):
        return np.array([-1, -1, -1])  # Return [-1, -1, -1] if any point is missing
    else:
        return calculate_normal(p1, p2, p3)  # Otherwise, calculate the normal as usual
        
# Function to calculate angle between three points
def calculate_angle(p1, p2, p3):
    # Create vectors from points p1, p2, p3
    v1 = p1 - p2
    v2 = p3 - p2
    
    # Calculate the cosine of the angle using dot product
    cos_theta = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
    angle = cos_theta
    
    return cos_theta

# Function to calculate the normal of the plane formed by three points
def calculate_normal(p1, p2, p3):
    # Vectors on the plane
    v1 = p2 - p1
    v2 = p3 - p1
    
    # Cross product gives the normal vector
    normal = np.cross(v1, v2)
    
    # Normalize the normal vector
    normal = normal / np.linalg.norm(normal)
    
    return normal

# Function to calculate the angle between the normal and each of the axes
def calculate_normal_angles(normal):
    # Calculate angles with x, y, z axes
    cos_values = []
    for axis in np.eye(3):  # x, y, z unit vectors
        cos_value = np.dot(normal, axis)
        cos_values.append(cos_value)
    return cos_values

# Function to calculate the x and y distance between two points
def calculate_xy_distance(p1, p2):
    x_distance = abs(p1[0] - p2[0])  # x-coordinate distance
    y_distance = abs(p1[1] - p2[1])  # y-coordinate distance
    return x_distance, y_distance


# Function to extract the pose features
def extract_pose_features(image, landmarks):
    # Define the landmark indices for the required sets of points (using Pose landmark indices)
    points_sets = {
        "angle_11_12_14": (get_coordinates_safe(landmarks, 11), get_coordinates_safe(landmarks, 12), get_coordinates_safe(landmarks, 14)),  # Left shoulder, right shoulder, right elbow
        "angle_12_14_16": (get_coordinates_safe(landmarks, 12), get_coordinates_safe(landmarks, 11), get_coordinates_safe(landmarks, 13)),  # Right shoulder, right elbow, right wrist
        "angle_11_13_15": (get_coordinates_safe(landmarks, 11), get_coordinates_safe(landmarks, 13), get_coordinates_safe(landmarks, 15)),  # Left shoulder, left elbow, left wrist
        "angle_13_15_17": (get_coordinates_safe(landmarks, 12), get_coordinates_safe(landmarks, 14), get_coordinates_safe(landmarks, 16)),  # Left elbow, left wrist, left hand
        "normal_1": (get_coordinates_safe(landmarks, 15), get_coordinates_safe(landmarks, 17), get_coordinates_safe(landmarks, 19)),  # Plane formed by left shoulder, left hip, left knee
        "normal_2": (get_coordinates_safe(landmarks, 16), get_coordinates_safe(landmarks, 18), get_coordinates_safe(landmarks, 20))   # Plane formed by right shoulder, right hip, right knee
    }

    # Calculate the angles between the specific sets of points
    angles = []
    for key, (p1, p2, p3) in points_sets.items():
        if key.startswith("angle"):
            angle = calculate_angle(p1, p2, p3)
            angles.append(angle)
    
    # Calculate normals and angles with axes
    for key, (p1, p2, p3) in points_sets.items():
        if key.startswith("normal"):
            normal = calculate_normal_safe(p1, p2, p3)  # Safe normal calculation
            if np.array_equal(normal, [-1, -1, -1]):
                # If normal is [-1, -1, -1], it indicates missing points, so append [-1, -1, -1] for each axis angle
                angles.extend([-1, -1, -1])
            else:
                normal_angles = calculate_normal_angles(normal)
                angles.extend(normal_angles)  # Append angles with x, y, z axes

    # Add the distance between points 15 (left wrist) and 16 (right wrist)
    p15 = get_coordinates_safe(landmarks, 15)  # Left wrist
    p16 = get_coordinates_safe(landmarks, 16)  # Right wrist
    x_distance, y_distance = calculate_xy_distance(p15, p16)
    angles.extend([x_distance, y_distance])  # Append x and y distance to the feature list
    
    return angles

# Function to process frames and extract features
def process_frames(data_folder):
    data = []
    labels = []
    
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
                results = pose.process(image_rgb)
                
                # If pose landmarks are detected, extract features
                if results.pose_landmarks:
                    landmarks = results.pose_landmarks.landmark
                    features = extract_pose_features(image, landmarks)
                    data.append(features)
                    labels.append(label)  # Only save the class label (e.g., "1")
    
    return data, labels

# Main processing
data_folder = './data' 
data, labels = process_frames(data_folder)

# Save the data and labels into a pickle file
output_file = 'pose.pkl'
with open(output_file, 'wb') as f:
    pickle.dump({'data': data, 'labels': labels}, f)

print(f"Pickle file saved at {output_file}")
