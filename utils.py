# import mediapipe as mp
import numpy as np
import cv2

class MediapipeUtils:
    """This class is a utility class for mediapipe containing all the required functions for mediapipe"""
    
    def __init__(self,mp_holistic,mp_drawing):
        self.mp_holistic = mp_holistic
        self.mp_drawing = mp_drawing
        
        self.features = []


    def mediapipe_detection(self,image, model) -> tuple:
        """Function to detect landmarks and pose from an image"""
        image_ = cv2.cvtColor(image, cv2.COLOR_BGR2RGB) 
        image_.flags.writeable = False                  
        results = model.process(image_) 
        image_.flags.writeable = True                   
        image = cv2.cvtColor(image_, cv2.COLOR_RGB2BGR) 
        return image, results

    def extract_keypoints(self,results) -> np.array:
        """Function to extract features from mediapipe results"""        
        pose = np.array([[res.x, res.y, res.z, res.visibility] for res in results.pose_landmarks.landmark]).flatten() if results.pose_landmarks else np.zeros(33*4)
        
        # face = np.array([[res.x, res.y, res.z] for res in results.face_landmarks.landmark]).flatten() if results.face_landmarks else np.zeros(468*3)
        # lh = np.array([[res.x, res.y, res.z] for res in results.left_hand_landmarks.landmark]).flatten() if results.left_hand_landmarks else np.zeros(21*3)
        # rh = np.array([[res.x, res.y, res.z] for res in results.right_hand_landmarks.landmark]).flatten() if results.right_hand_landmarks else np.zeros(21*3)
        # return np.concatenate([pose, lh, rh])    
        return pose   
    def extract_features(self, results):
        """Extract features from pose landmarks."""
        self.features = []

        # Extract X, Y, Z coordinates for specified landmarks
        landmark_indices = [13, 14, 15, 16]
        for idx in landmark_indices:
            lm = results[idx]
            self.features.extend([lm.x, lm.y, lm.z])

        # Left arm: vectors 15-13 and 13-11
        left_wrist = np.array([results[15].x, results[15].y, results[15].z])
        left_elbow = np.array([results[13].x, results[13].y, results[13].z])
        left_shoulder = np.array([results[11].x, results[11].y, results[11].z])

        vector_left_wrist_elbow = left_wrist - left_elbow
        vector_left_elbow_shoulder = left_elbow - left_shoulder

        # Calculate angle
        angle_left_arm = self.calculate_angles_between(vector_left_wrist_elbow, vector_left_elbow_shoulder)

        # Convert angle to radians
        angle_left_arm_rad = np.deg2rad(angle_left_arm)

        # Compute sine and cosine
        sin_left_arm = np.sin(angle_left_arm_rad)
        cos_left_arm = np.cos(angle_left_arm_rad)

        # Right arm: vectors 16-14 and 14-12
        right_wrist = np.array([results[16].x, results[16].y, results[16].z])
        right_elbow = np.array([results[14].x, results[14].y, results[14].z])
        right_shoulder = np.array([results[12].x, results[12].y, results[12].z])

        vector_right_wrist_elbow = right_wrist - right_elbow
        vector_right_elbow_shoulder = right_elbow - right_shoulder

        angle_right_arm = self.calculate_angles_between(vector_right_wrist_elbow, vector_right_elbow_shoulder)

        angle_right_arm_rad = np.deg2rad(angle_right_arm)
        sin_right_arm = np.sin(angle_right_arm_rad)
        cos_right_arm = np.cos(angle_right_arm_rad)

        # Extend sine and cosine of angles into features
        self.features.extend([sin_left_arm, cos_left_arm, sin_right_arm, cos_right_arm])

        # Shoulders: compute angles and apply sine and cosine transformation
        # Right shoulder: vectors 12-14 and 11-12
        vector_11_12 = left_shoulder - right_shoulder  # 11-12
        vector_12_14 = right_shoulder - right_elbow    # 12-14
        angle_right_shoulder = self.calculate_angles_between(vector_11_12, vector_12_14)
        angle_right_shoulder_rad = np.deg2rad(angle_right_shoulder)
        sin_right_shoulder = np.sin(angle_right_shoulder_rad)
        cos_right_shoulder = np.cos(angle_right_shoulder_rad)

        # Left shoulder: vectors 11-13 and 11-12
        vector_11_13 = left_shoulder - left_elbow      # 11-13
        angle_left_shoulder = self.calculate_angles_between(vector_11_12, vector_11_13)
        angle_left_shoulder_rad = np.deg2rad(angle_left_shoulder)
        sin_left_shoulder = np.sin(angle_left_shoulder_rad)
        cos_left_shoulder = np.cos(angle_left_shoulder_rad)

        self.features.extend([sin_left_shoulder, cos_left_shoulder, sin_right_shoulder, cos_right_shoulder])

        # Distance between points 15 and 16 (hands)
        left_hand = results[15]
        right_hand = results[16]
        center = results[0]

        distance_hands = self.calculate_distance(left_hand, right_hand)
        distance_left_hand_center = self.calculate_distance(left_hand, center)
        distance_right_hand_center = self.calculate_distance(right_hand, center)

        # Extend distances into features
        self.features.extend([distance_hands, distance_left_hand_center, distance_right_hand_center])

        # Extract hand direction vectors (optional)
        direction_vector_left_hand = self.extract_hand_direction(15, 17, 19, results)
        direction_vector_right_hand = self.extract_hand_direction(16, 18, 20, results)

        # Extend hand direction components into features
        self.features.extend(direction_vector_left_hand)
        self.features.extend(direction_vector_right_hand)

        return self.features
    
    def extract_hand_direction(self, wrist, pinky, index, results):
        """Extracts the direction vector of the hand."""
        wrist = np.array([results[wrist].x, results[wrist].y, results[wrist].z])
        pinky = np.array([results[pinky].x, results[pinky].y, results[pinky].z])
        index = np.array([results[index].x, results[index].y, results[index].z])

        # Calculate vectors on the hand plane
        vector_a = pinky - wrist
        vector_b = index - wrist

        # Compute normal vector (hand plane normal)
        normal_vector = np.cross(vector_a, vector_b)
        normal_vector /= np.linalg.norm(normal_vector)

        # Compute direction vector (from wrist to midpoint of pinky and index)
        mid_finger = (pinky + index) / 2
        direction_vector = mid_finger - wrist
        direction_vector /= np.linalg.norm(direction_vector)

        return direction_vector
    
    def draw_styled_landmarks(self,image, results) -> None:
        """Function to draw pose connections"""
        self.mp_drawing.draw_landmarks(image, results.pose_landmarks, self.mp_holistic.POSE_CONNECTIONS,
                                self.mp_drawing.DrawingSpec(color=(80,22,10), thickness=2, circle_radius=4), 
                                self.mp_drawing.DrawingSpec(color=(80,44,121), thickness=2, circle_radius=2)
                                ) 
        
        # Draw left hand connections
        # self.mp_drawing.draw_landmarks(image, results.left_hand_landmarks, self.mp_holistic.HAND_CONNECTIONS, 
        #                         self.mp_drawing.DrawingSpec(color=(121,22,76), thickness=2, circle_radius=4), 
        #                         self.mp_drawing.DrawingSpec(color=(121,44,250), thickness=2, circle_radius=2)
        #                         ) 
        
        # # Draw right hand connections  
        # self.mp_drawing.draw_landmarks(image, results.right_hand_landmarks, self.mp_holistic.HAND_CONNECTIONS, 
        #                         self.mp_drawing.DrawingSpec(color=(245,117,66), thickness=2, circle_radius=4), 
        #                         self.mp_drawing.DrawingSpec(color=(245,66,230), thickness=2, circle_radius=2)
        #                         ) 
    
    
    def calculate_angles_between(self,vector1, vector2):
        """Function to calculate angles between two vectors"""
        unit_vector1 = vector1 / np.linalg.norm(vector1)
        unit_vector2 = vector2 / np.linalg.norm(vector2)
        dot_product = np.dot(unit_vector1, unit_vector2)
        self.angle = np.degrees(np.arccos(np.clip(dot_product, -1.0, 1.0)))
        return self.angle

    def calculate_angles(self,vector):
        """
        Calculate the angles between the given vector and the x, y, and z axes in degrees.
        """
        x_axis = np.array([1, 0, 0])
        y_axis = np.array([0, 1, 0])
        z_axis = np.array([0, 0, 1])

        vector = vector / np.linalg.norm(vector)  # Normalize the vector

        self.angle_x = np.degrees(np.arccos(np.clip(np.dot(vector, x_axis), -1.0, 1.0)))
        self.angle_y = np.degrees(np.arccos(np.clip(np.dot(vector, y_axis), -1.0, 1.0)))
        self.angle_z = np.degrees(np.arccos(np.clip(np.dot(vector, z_axis), -1.0, 1.0)))

        return self.angle_x, self.angle_y, self.angle_z

    def calculate_distance(self, lm1, lm2):
        """Function to calculate distance between two landmarks"""
        self.dist = np.sqrt((lm1.x - lm2.x) ** 2 + (lm1.y - lm2.y) ** 2 + (lm1.z - lm2.z) ** 2)
        return self.dist
