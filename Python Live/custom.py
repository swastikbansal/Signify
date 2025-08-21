import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix
import numpy as np
import json
import cv2
import mediapipe as mp
import pickle
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split


import os
data_folder = 'Dataset'

data = []
labels = []

os.makedirs('MP_data', exist_ok=True)

SAVE_PATH = 'MP_data'


# Initializing Mediapipe solutions for hand and pose detection
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=2, 
                       min_detection_confidence=0.5, 
                       min_tracking_confidence=0.5)

mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.5, 
                    min_tracking_confidence=0.5)



def calculate_angle(vec1, vec2):
    """
    Calculate the cosine of the angle between two vectors.
    """
    dot_product = np.dot(vec1, vec2)
    norm_vec1 = np.linalg.norm(vec1)
    norm_vec2 = np.linalg.norm(vec2)
    cosine_angle = dot_product / (norm_vec1 * norm_vec2)
    return cosine_angle

def extract_hand_features(image, hand_landmarks, pose_landmarks=None):
    """
    Extract features from hand landmarks, including angles between vectors and axes,
    and distances between specific landmarks.
    """
    hand_pairs = [
        (1, 3),  # Thumb
        (6, 8),  # Index finger
        (10, 12),  # Middle finger
        (14, 16),  # Ring finger
        (18, 20),  # Pinky finger
        (0, 9)  # Palm direction
    ]
    
    features = []
    
    for pair in hand_pairs:
        landmark1 = hand_landmarks[pair[0]]
        landmark2 = hand_landmarks[pair[1]]
        
        vector = np.array([landmark2.x - landmark1.x, landmark2.y - landmark1.y, landmark2.z - landmark1.z])
        
        x_axis = np.array([1, 0, 0])
        y_axis = np.array([0, 1, 0])
        z_axis = np.array([0, 0, 1])
        
        angle_x = calculate_angle(vector, x_axis)
        angle_y = calculate_angle(vector, y_axis)
        angle_z = calculate_angle(vector, z_axis)
        
        features.extend([angle_x, angle_y, angle_z])
    
    vector_0_to_5 = np.array([
        hand_landmarks[5].x - hand_landmarks[0].x,
        hand_landmarks[5].y - hand_landmarks[0].y,
        hand_landmarks[5].z - hand_landmarks[0].z
    ])
    
    vector_0_to_17 = np.array([
        hand_landmarks[17].x - hand_landmarks[0].x,
        hand_landmarks[17].y - hand_landmarks[0].y,
        hand_landmarks[17].z - hand_landmarks[0].z
    ])
    
    normal_vector = np.cross(vector_0_to_5, vector_0_to_17)
    
    normal_angle_x = calculate_angle(normal_vector, x_axis)
    normal_angle_y = calculate_angle(normal_vector, y_axis)
    normal_angle_z = calculate_angle(normal_vector, z_axis)
    
    features.extend([normal_angle_x, normal_angle_y, normal_angle_z])
    
    if pose_landmarks:
        nose_landmark = pose_landmarks[0]
        wrist_landmark = hand_landmarks[0]
        
        distance_x = abs(nose_landmark.x - wrist_landmark.x)
        distance_y = abs(nose_landmark.y - wrist_landmark.y)
        
        features.extend([distance_x, distance_y])
    
    return features


# Iterate through each class folder in the data directory
for label in os.listdir(data_folder):
    class_folder = os.path.join(data_folder, label)
    
    if os.path.isdir(class_folder):
        # Iterate through each image in the class folder
        for image_name in os.listdir(class_folder):
            image_path = os.path.join(class_folder, image_name)
            
            image = cv2.imread(image_path)
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            results = hands.process(image_rgb)
            
            pose_results = pose.process(image_rgb)
            
            # If hands are detected, extract features for the left hand
            if results.multi_hand_landmarks:
                for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
                    if handedness.classification[0].label == 'Left':
                        if pose_results.pose_landmarks:
                            features = extract_hand_features(image, hand_landmarks.landmark, pose_results.pose_landmarks.landmark)
                            data.append(features)
                            labels.append(label)


# Save the extracted data and labels for left hand into a JSON file

def merge_and_save_json(new_data, new_labels, json_path):
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            old = json.load(f)
        merged_data = old.get('data', []) + new_data
        merged_labels = old.get('labels', []) + new_labels
    else:
        merged_data = new_data
        merged_labels = new_labels
    with open(json_path, 'w') as f:
        json.dump({'data': merged_data, 'labels': merged_labels}, f)
    print(f"JSON file merged and saved at {json_path}")

# For left hand
output_file_json = f'{SAVE_PATH}/left.json'
merge_and_save_json(data, labels, output_file_json)



# Iterate through the classes folder
for label in os.listdir(data_folder):
    class_folder = os.path.join(data_folder, label)
    
    if os.path.isdir(class_folder):
        # Iterate through images in each class folder
        for image_name in os.listdir(class_folder):
            image_path = os.path.join(class_folder, image_name)
        
            image = cv2.imread(image_path)
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            results = hands.process(image_rgb)
            
            image_pose_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            pose_results = pose.process(image_pose_rgb)
            
            # If hands are detected, extract features for the right hand
            if results.multi_hand_landmarks:
                for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
                    if handedness.classification[0].label == 'Right':
                        if pose_results.pose_landmarks:
                            features = extract_hand_features(image, hand_landmarks.landmark, pose_results.pose_landmarks.landmark)
                            data.append(features)
                            labels.append(label)  



# Save the extracted data and labels for right hand into a JSON file
output_file_json = f'{SAVE_PATH}/right.json'
merge_and_save_json(data, labels, output_file_json)



def get_coordinates_safe(landmark, index):
    """
    Safely retrieves the x, y, z coordinates of a given landmark index.
    Returns [-1, -1, -1] if the landmark is not found.
    """
    try:
        return np.array([landmark[index].x, landmark[index].y, landmark[index].z])
    except IndexError:
        return np.array([-1, -1, -1])

def calculate_normal_safe(p1, p2, p3):
    """
    Safely calculates the normal vector of the plane formed by three points.
    Returns [-1, -1, -1] if any point is missing.
    """
    if np.array_equal(p1, [-1, -1, -1]) or np.array_equal(p2, [-1, -1, -1]) or np.array_equal(p3, [-1, -1, -1]):
        return np.array([-1, -1, -1])
    else:
        return calculate_normal(p1, p2, p3)

def calculate_angle(p1, p2, p3):
    """
    Calculates the cosine of the angle at p2 formed by the vectors p1->p2 and p3->p2.
    """
    v1 = p1 - p2
    v2 = p3 - p2
    cos_theta = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
    return cos_theta

def calculate_normal(p1, p2, p3):
    """
    Calculates the normal vector of the plane formed by three points.
    """
    v1 = p2 - p1
    v2 = p3 - p1
    normal = np.cross(v1, v2)
    normal = normal / np.linalg.norm(normal)
    return normal

def calculate_normal_angles(normal):
    """
    Calculates the angles between the normal vector and the x, y, z axes.
    """
    cos_values = []
    for axis in np.eye(3):  # x, y, z unit vectors
        cos_value = np.dot(normal, axis)
        cos_values.append(cos_value)
    return cos_values

def calculate_xy_distance(p1, p2):
    """
    Calculates the x and y distances between two points.
    """
    x_distance = abs(p1[0] - p2[0])
    y_distance = abs(p1[1] - p2[1])
    return x_distance, y_distance

def extract_pose_features(image, landmarks):
    """
    Extracts pose features including angles between specific joints and distances between landmarks.
    """
    points_sets = {
        "angle_11_12_14": (get_coordinates_safe(landmarks, 11), get_coordinates_safe(landmarks, 12), get_coordinates_safe(landmarks, 14)),  # Left shoulder, right shoulder, right elbow
        "angle_12_14_16": (get_coordinates_safe(landmarks, 12), get_coordinates_safe(landmarks, 11), get_coordinates_safe(landmarks, 13)),  # Right shoulder, right elbow, right wrist
        "angle_11_13_15": (get_coordinates_safe(landmarks, 11), get_coordinates_safe(landmarks, 13), get_coordinates_safe(landmarks, 15)),  # Left shoulder, left elbow, left wrist
        "angle_13_15_17": (get_coordinates_safe(landmarks, 12), get_coordinates_safe(landmarks, 14), get_coordinates_safe(landmarks, 16)),  # Left elbow, left wrist, left hand
        "normal_1": (get_coordinates_safe(landmarks, 15), get_coordinates_safe(landmarks, 17), get_coordinates_safe(landmarks, 19)),  # Plane formed by left shoulder, left hip, left knee
        "normal_2": (get_coordinates_safe(landmarks, 16), get_coordinates_safe(landmarks, 18), get_coordinates_safe(landmarks, 20))   # Plane formed by right shoulder, right hip, right knee
    }

    angles = []
    for key, (p1, p2, p3) in points_sets.items():
        if key.startswith("angle"):
            angle = calculate_angle(p1, p2, p3)
            angles.append(angle)
    
    for key, (p1, p2, p3) in points_sets.items():
        if key.startswith("normal"):
            normal = calculate_normal_safe(p1, p2, p3)
            if np.array_equal(normal, [-1, -1, -1]):
                angles.extend([-1, -1, -1])
            else:
                normal_angles = calculate_normal_angles(normal)
                angles.extend(normal_angles)

    p15 = get_coordinates_safe(landmarks, 15)  # Left wrist
    p16 = get_coordinates_safe(landmarks, 16)  # Right wrist
    x_distance, y_distance = calculate_xy_distance(p15, p16)
    angles.extend([x_distance, y_distance])
    
    return angles



def process_frames(data_folder):
    """
    Processes images in the data folder to extract pose features and labels.
    """
    data = []
    labels = []
    
    for label in os.listdir(data_folder):
        class_folder = os.path.join(data_folder, label)
        
        if os.path.isdir(class_folder):
            for image_name in os.listdir(class_folder):
                image_path = os.path.join(class_folder, image_name)
                
                image = cv2.imread(image_path)
                image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                results = pose.process(image_rgb)
                
                if results.pose_landmarks:
                    landmarks = results.pose_landmarks.landmark
                    features = extract_pose_features(image, landmarks)
                    data.append(features)
                    labels.append(label)
    
    return data, labels

data, labels = process_frames(data_folder)



# Save the data and labels for pose into a JSON file
output_file_json = f'{SAVE_PATH}/pose.json'
merge_and_save_json(data, labels, output_file_json)


#Train a Random Forest Classifier on the extracted features

def compute_accuracy(y_true, y_pred):
    correct_predictions = sum(1 for true_label, predicted in zip(y_true, y_pred) if true_label == predicted)
    return correct_predictions / len(y_true)

def load_json_data(json_path):
    with open(json_path, 'r') as f:
        data_dict = json.load(f)
    X = np.array(data_dict['data'])
    y = np.array(data_dict['labels'])
    return X, y

def train_and_save_model_json(json_path, model_path):
    X, y = load_json_data(json_path)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=True, stratify=y
    )
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=6,
        min_samples_split=3,
        min_samples_leaf=2,
        bootstrap=True,
        criterion='entropy',
        oob_score=True
    )
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    acc = np.mean(y_pred == y_test)
    print(f"{model_path}: {acc * 100:.2f}% of samples classified correctly!")
    with open(model_path, 'wb') as f:
        pickle.dump({'model': model}, f)

# Train and save all three models using JSON data files
train_and_save_model_json('MP_data/pose.json', 'Models/pose_model_json.p')
train_and_save_model_json('MP_data/left.json', 'Models/left_model_json.p')
train_and_save_model_json('MP_data/right.json', 'Models/right_model_json.p')


# Function to plot confusion matrix from JSON data
def plot_conf_matrix_json(model_path, json_path, title):
    with open(model_path, 'rb') as f:
        model = pickle.load(f)['model']
    with open(json_path, 'r') as f:
        data_dict = json.load(f)
    X = np.array(data_dict['data'])
    y = np.array(data_dict['labels'])
    from sklearn.model_selection import train_test_split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=True, stratify=y
    )
    y_pred = model.predict(X_test)
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(6, 5))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=np.unique(y_test),
                yticklabels=np.unique(y_test))
    plt.title(f'Confusion Matrix - {title}')
    plt.xlabel('Predicted')
    plt.ylabel('True')
    plt.show()

plot_conf_matrix_json('Models/pose_model_json.p', 'MP_data/pose.json', 'Pose (JSON)')
plot_conf_matrix_json('Models/left_model_json.p', 'MP_data/left.json', 'Left Hand (JSON)')
plot_conf_matrix_json('Models/right_model_json.p', 'MP_data/right.json', 'Right Hand (JSON)')
