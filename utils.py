import numpy as np
import time

class Utils:
    def __init__(self, axes, restSpeed, minPoints, requiredFrames):
        self.axes = axes
        self.REST_SPEED_THRESHOLD = restSpeed  # pixels/second; lower => more sensitive to rest
        self.MIN_POINTS_FOR_REST = minPoints
        self.REQUIRED_CONSECUTIVE_FRAMES = requiredFrames

    def _landmark_to_pixel(self, landmark, img_shape):
        """Convert normalized landmark to pixel (x,y)."""
        h, w = img_shape[0], img_shape[1]
        return np.array([landmark.x * w, landmark.y * h], dtype=float)

    def is_resting(self, res_hands, img_shape):
        """
        Compute average speed (pixels/sec) for selected landmarks across frames.
        Returns True if movement is below REST_SPEED_THRESHOLD.
        """
        
        # Global previous positions and timing for rest detection
        prev_positions = {
            "left_wrist": None,
            "right_wrist": None,
            "left_shoulder": None,
            "right_shoulder": None,
            "timestamp": None,
            # per-landmark counters for consecutive low-speed frames
            "counters": {
                "left_wrist": 0,
                "right_wrist": 0,
                "left_shoulder": 0,
                "right_shoulder": 0
            }
        }

        current_time = time.time()
        points = {}
        
        # Hands: get wrist landmark (index 0) if available
        if getattr(res_hands, "multi_hand_landmarks", None) and getattr(res_hands, "multi_handedness", None):
            for hand_landmarks, handedness in zip(res_hands.multi_hand_landmarks, res_hands.multi_handedness):
                label = handedness.classification[0].label
                try:
                    wrist = self._landmark_to_pixel(hand_landmarks.landmark[0], img_shape)
                except Exception:
                    continue

                if label == 'Left':
                    points['left_wrist'] = wrist
                elif label == 'Right':
                    points['right_wrist'] = wrist

        # Initialize previous timestamp if missing
        if prev_positions['timestamp'] is None:
            prev_positions['timestamp'] = current_time
            prev_positions.update({k: v for k, v in points.items()})
            return False
        
        # Update prev and return False if there is lack of lm's (not resting)
        if len(points) < 1:
            prev_positions['timestamp'] = current_time
            prev_positions.update({k: v for k, v in points.items()})
            
            # reset counters if no data for those keys
            for k in prev_positions['counters']:
                if k not in points:
                    prev_positions['counters'][k] = 0
            return False
        
        dt = current_time - prev_positions['timestamp']
        if dt <= 0:
            prev_positions['timestamp'] = current_time
            prev_positions.update({k: v for k, v in points.items()})
            return False

        speeds = []
        speed_map = {}
        for key, cur_pos in points.items():
            prev_pos = prev_positions.get(key)
            if prev_pos is not None:
                dist = np.linalg.norm(cur_pos - prev_pos)
                speed = dist / dt
                speeds.append(speed)
                speed_map[key] = speed

        # updating prev pos & time
        prev_positions['timestamp'] = current_time
        prev_positions.update({k: v for k, v in points.items()})

        # Restting counters for disappered landmarks
        for k in list(prev_positions['counters'].keys()):
            if k not in speed_map:
                prev_positions['counters'][k] = 0

        # Using avg speed to detect on enough lm's
        if len(speeds) >= self.MIN_POINTS_FOR_REST:
            avg_speed = float(np.mean(speeds))
            for k in prev_positions['counters']:
                prev_positions['counters'][k] = 0 # reset counters on insufficient data
            return avg_speed < self.REST_SPEED_THRESHOLD

        # Case for a single hand 
        if len(speeds) == 1:
            key = next(iter(speed_map))
            speed = speed_map[key]
            if speed < self.REST_SPEED_THRESHOLD:
                prev_positions['counters'][key] = prev_positions['counters'].get(key, 0) + 1
                if prev_positions['counters'][key] >= self.REQUIRED_CONSECUTIVE_FRAMES:
                    return True
                else:
                    return False
            else:
                prev_positions['counters'][key] = 0
                return False

        return False

    
    def calculate_angle1(self, vec1, vec2):
        dot_product = np.dot(vec1, vec2)
        norm_vec1 = np.linalg.norm(vec1)
        norm_vec2 = np.linalg.norm(vec2)
        self.cosine_angle = dot_product / (norm_vec1 * norm_vec2)
        return self.cosine_angle  

    def get_coordinates_safe(self, landmark, index):
        try:
            return np.array([landmark[index].x, landmark[index].y, landmark[index].z])
        except IndexError:
            return np.array([-1, -1, -1])  


    def angle_between_vectors(self, v1, v2):
        dot_product = np.dot(v1, v2)
        magnitude_v1 = np.linalg.norm(v1)
        magnitude_v2 = np.linalg.norm(v2)
        cos_theta = dot_product / (magnitude_v1 * magnitude_v2)
        cos_theta = np.clip(cos_theta, -1.0, 1.0)
        self.theta = np.arccos(cos_theta)
        return np.degrees(self.theta)

    # Function to classify palm orientation
    def get_palm_orientation(self, normal):
        angles = {axis: self.angle_between_vectors(normal, direction) for axis, direction in self.axes.items()}
        # Find the axis with the smallest angle
        self.best_match_axis = min(angles, key=angles.get)
        return self.best_match_axis


    # Function to extract hand features (angles between vectors and axes)
    def extract_features(self, hand_landmarks, pose_landmarks=None):
        hand_pairs = [
            (1 , 3) ,  # Thumb
            (6 , 8 ),  # Index finger
            (10, 12),  # Middle finger
            (14, 16),  # Ring finger
            (18, 20),  # Pinky finger
            (0 , 9)  # Palm direction
        ]
        
        self.features = []
        for pair in hand_pairs:
            landmark1 = hand_landmarks[pair[0]]
            landmark2 = hand_landmarks[pair[1]]
            
            vector = np.array([landmark2.x - landmark1.x, landmark2.y - landmark1.y, landmark2.z - landmark1.z])
            x_axis = np.array([1, 0, 0])
            y_axis = np.array([0, 1, 0])
            z_axis = np.array([0, 0, 1])
            
            angle_x = self.calculate_angle1(vector, x_axis)
            angle_y = self.calculate_angle1(vector, y_axis)
            angle_z = self.calculate_angle1(vector, z_axis)
            
            self.features.extend([angle_x, angle_y, angle_z])
        
        # Safe access to landmarks for 0, 5, and 17
        vector_0_to_5 = self.get_coordinates_safe(hand_landmarks, 5) - self.get_coordinates_safe(hand_landmarks, 0)
        vector_0_to_17 = self.get_coordinates_safe(hand_landmarks, 17) - self.get_coordinates_safe(hand_landmarks, 0)
        
        normal_vector = np.cross(vector_0_to_5, vector_0_to_17)
        
        normal_angle_x = self.calculate_angle1(normal_vector, x_axis)
        normal_angle_y = self.calculate_angle1(normal_vector, y_axis)
        normal_angle_z = self.calculate_angle1(normal_vector, z_axis)
        
        self.features.extend([normal_angle_x, normal_angle_y, normal_angle_z])
        
        # If pose landmarks are available, calculate the distance between nose and wrist
        
        nose_landmark = self.get_coordinates_safe(pose_landmarks, 0)  # Nose is at index 0 in pose landmarks
        wrist_landmark = self.get_coordinates_safe(hand_landmarks, 0)  # Wrist is at index 0 in hand landmarks
            
        # Calculate the distance in the x and y axes
        distance_x = abs(nose_landmark[0] - wrist_landmark[0])
        distance_y = abs(nose_landmark[1] - wrist_landmark[1])
            
        # Append the x and y distances as new features
        self.features.extend([distance_x, distance_y])
        
        return self.features

    #Initialize pose extraction functions
    def calculate_normal_safe(self,p1, p2, p3):
        # Check if any of the points is [-1, -1, -1] (default value for missing landmarks)
        if np.array_equal(p1, [-1, -1, -1]) or np.array_equal(p2, [-1, -1, -1]) or np.array_equal(p3, [-1, -1, -1]):
            return np.array([-1, -1, -1])  # Return [-1, -1, -1] if any point is missing
        else:
            return self.calculate_normal(p1, p2, p3)  # Otherwise, calculate the normal as usual
        
    # Function to calculate angle between three points
    def calculate_angle2(self,p1, p2, p3):
        # Create vectors from points p1, p2, p3
        v1 = p1 - p2
        v2 = p3 - p2
        
        # Calculate the cosine of the angle using dot product
        self.cos_theta = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
        
        return self.cos_theta

    # Function to calculate the normal of the plane formed by three points
    def calculate_normal(self, p1, p2, p3):
        # Vectors on the plane
        v1 = p2 - p1
        v2 = p3 - p1
        
        # Cross product gives the normal vector
        self.normal = np.cross(v1, v2)
        
        # Normalize the normal vector
        self.normal = self.normal / np.linalg.norm(self.normal)
        
        return self.normal

    # Function to calculate the angle between the normal and each of the axes
    def calculate_normal_angles(self,normal):
        # Calculate angles with x, y, z axes
        self.cos_values = []
        for axis in np.eye(3):  # x, y, z unit vectors
            cos_value = np.dot(normal, axis)
            self.cos_values.append(cos_value)
        return self.cos_values

    # Function to calculate the x and y distance between two points
    def calculate_xy_distance(self, p1, p2):
        self.x_distance = abs(p1[0] - p2[0])  
        self.y_distance = abs(p1[1] - p2[1])  
        return self.x_distance, self.y_distance

    # Function to extract the pose features
    def extract_pose_features(self, landmarks):
        # Define the landmark indices for the required sets of points (using Pose landmark indices)
        points_sets = {
            "angle_11_12_14": (self.get_coordinates_safe(landmarks, 11), self.get_coordinates_safe(landmarks, 12), self.get_coordinates_safe(landmarks, 14)),  # Left shoulder, right shoulder, right elbow
            "angle_12_14_16": (self.get_coordinates_safe(landmarks, 12), self.get_coordinates_safe(landmarks, 11), self.get_coordinates_safe(landmarks, 13)),  # Right shoulder, right elbow, right wrist
            "angle_11_13_15": (self.get_coordinates_safe(landmarks, 11), self.get_coordinates_safe(landmarks, 13), self.get_coordinates_safe(landmarks, 15)),  # Left shoulder, left elbow, left wrist
            "angle_13_15_17": (self.get_coordinates_safe(landmarks, 12), self.get_coordinates_safe(landmarks, 14), self.get_coordinates_safe(landmarks, 16)),  # Left elbow, left wrist, left hand
            "normal_1": (self.get_coordinates_safe(landmarks, 15), self.get_coordinates_safe(landmarks, 17), self.get_coordinates_safe(landmarks, 19)),  # Plane formed by left shoulder, left hip, left knee
            "normal_2": (self.get_coordinates_safe(landmarks, 16), self.get_coordinates_safe(landmarks, 18), self.get_coordinates_safe(landmarks, 20))   # Plane formed by right shoulder, right hip, right knee
        }

        # Calculate the angles between the specific sets of points
        self.angles = []
        for key, (p1, p2, p3) in points_sets.items():
            if key.startswith("angle"):
                angle = self.calculate_angle2(p1, p2, p3)
                self.angles.append(angle)
        
        # Calculate normals and angles with axes
        for key, (p1, p2, p3) in points_sets.items():
            if key.startswith("normal"):
                normal = self.calculate_normal_safe(p1, p2, p3)  # Safe normal calculation
                if np.array_equal(normal, [-1, -1, -1]):
                    # If normal is [-1, -1, -1], it indicates missing points, so append [-1, -1, -1] for each axis angle
                    self.angles.extend([-1, -1, -1])
                else:
                    normal_angles = self.calculate_normal_angles(normal)
                    self.angles.extend(normal_angles)  # Append angles with x, y, z axes

        # Add the distance between points 15 (left wrist) and 16 (right wrist)
        p15 = self.get_coordinates_safe(landmarks, 15)  # Left wrist
        p16 = self.get_coordinates_safe(landmarks, 16)  # Right wrist
        x_distance, y_distance = self.calculate_xy_distance(p15, p16)
        self.angles.extend([x_distance, y_distance])  # Append x and y distance to the feature list
        
        return self.angles