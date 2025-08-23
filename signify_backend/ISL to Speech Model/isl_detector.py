import pickle
import threading
import os

import cv2
import mediapipe as mp
import numpy as np
import pyttsx3
import tensorflow as tf


def load_models():
    """Load pre-trained models from pickle files"""
    left_model_filename = r"Model31\left_model.p"
    right_model_filename = r"Model31\right_model.p"
    pose_model_filename = r"Model31\pose_model.p"

    with open(left_model_filename, "rb") as f:
        left_model_data = pickle.load(f)
        left_model = left_model_data["model"]

    with open(right_model_filename, "rb") as f:
        right_model_data = pickle.load(f)
        right_model = right_model_data["model"]

    with open(pose_model_filename, "rb") as f:
        pose_model_data = pickle.load(f)
        pose_model = pose_model_data["model"]

    return left_model, right_model, pose_model


def initialize_mediapipe():
    """Initialize MediaPipe hands and pose detectors"""
    mp_hands = mp.solutions.hands
    mp_pose = mp.solutions.pose

    hands = mp_hands.Hands(
        max_num_hands=2, min_detection_confidence=0.7, min_tracking_confidence=0.7
    )
    pose = mp_pose.Pose(min_detection_confidence=0.7, min_tracking_confidence=0.7)

    return hands, pose, mp_hands, mp_pose


def calculate_angle1(vec1, vec2):
    """Function to calculate the angle between two vectors"""
    dot_product = np.dot(vec1, vec2)
    norm_vec1 = np.linalg.norm(vec1)
    norm_vec2 = np.linalg.norm(vec2)
    cosine_angle = dot_product / (norm_vec1 * norm_vec2)
    return cosine_angle


def get_coordinates_safe(landmark, index):
    """Safely get coordinates from landmark"""
    try:
        return np.array([landmark[index].x, landmark[index].y, landmark[index].z])
    except IndexError:
        return np.array([-1, -1, -1])


def angle_between_vectors(v1, v2):
    """Calculate angle between two vectors"""
    dot_product = np.dot(v1, v2)
    magnitude_v1 = np.linalg.norm(v1)
    magnitude_v2 = np.linalg.norm(v2)
    cos_theta = dot_product / (magnitude_v1 * magnitude_v2)
    cos_theta = np.clip(cos_theta, -1.0, 1.0)
    theta = np.arccos(cos_theta)
    return np.degrees(theta)


def get_palm_orientation(normal):
    """Function to classify palm orientation"""
    axes = {
        "x": np.array([1, 0, 0]),
        "-x": np.array([-1, 0, 0]),
        "y": np.array([0, 1, 0]),
        "-y": np.array([0, -1, 0]),
        "z": np.array([0, 0, 1]),
        "-z": np.array([0, 0, -1]),
    }

    angles = {
        axis: angle_between_vectors(normal, direction)
        for axis, direction in axes.items()
    }
    best_match_axis = min(angles, key=angles.get)
    return best_match_axis


def extract_features(hand_landmarks, pose_landmarks=None):
    """Function to extract hand features (angles between vectors and axes)"""
    hand_pairs = [
        (1, 3),  # Thumb
        (6, 8),  # Index finger
        (10, 12),  # Middle finger
        (14, 16),  # Ring finger
        (18, 20),  # Pinky finger
        (0, 9),  # Palm direction
    ]

    features = []
    for pair in hand_pairs:
        landmark1 = hand_landmarks[pair[0]]
        landmark2 = hand_landmarks[pair[1]]

        vector = np.array(
            [
                landmark2.x - landmark1.x,
                landmark2.y - landmark1.y,
                landmark2.z - landmark1.z,
            ]
        )
        x_axis = np.array([1, 0, 0])
        y_axis = np.array([0, 1, 0])
        z_axis = np.array([0, 0, 1])

        angle_x = calculate_angle1(vector, x_axis)
        angle_y = calculate_angle1(vector, y_axis)
        angle_z = calculate_angle1(vector, z_axis)

        features.extend([angle_x, angle_y, angle_z])

    # Safe access to landmarks for 0, 5, and 17
    vector_0_to_5 = get_coordinates_safe(hand_landmarks, 5) - get_coordinates_safe(
        hand_landmarks, 0
    )
    vector_0_to_17 = get_coordinates_safe(hand_landmarks, 17) - get_coordinates_safe(
        hand_landmarks, 0
    )

    normal_vector = np.cross(vector_0_to_5, vector_0_to_17)

    x_axis = np.array([1, 0, 0])
    y_axis = np.array([0, 1, 0])
    z_axis = np.array([0, 0, 1])

    normal_angle_x = calculate_angle1(normal_vector, x_axis)
    normal_angle_y = calculate_angle1(normal_vector, y_axis)
    normal_angle_z = calculate_angle1(normal_vector, z_axis)

    features.extend([normal_angle_x, normal_angle_y, normal_angle_z])

    # If pose landmarks are available, calculate the distance between nose and wrist
    if pose_landmarks:
        nose_landmark = get_coordinates_safe(pose_landmarks, 0)  # Nose is at index 0
        wrist_landmark = get_coordinates_safe(hand_landmarks, 0)  # Wrist is at index 0

        # Calculate the distance in the x and y axes
        distance_x = abs(nose_landmark[0] - wrist_landmark[0])
        distance_y = abs(nose_landmark[1] - wrist_landmark[1])

        features.extend([distance_x, distance_y])
    else:
        features.extend([0, 0])  # Default values if no pose landmarks

    return features


def calculate_normal_safe(p1, p2, p3):
    """Check if any of the points is [-1, -1, -1] (default value for missing landmarks)"""
    if (
        np.array_equal(p1, [-1, -1, -1])
        or np.array_equal(p2, [-1, -1, -1])
        or np.array_equal(p3, [-1, -1, -1])
    ):
        return np.array([-1, -1, -1])
    else:
        return calculate_normal(p1, p2, p3)


def calculate_angle2(p1, p2, p3):
    """Function to calculate angle between three points"""
    v1 = p1 - p2
    v2 = p3 - p2
    cos_theta = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
    return cos_theta


def calculate_normal(p1, p2, p3):
    """Function to calculate the normal of the plane formed by three points"""
    v1 = p2 - p1
    v2 = p3 - p1
    normal = np.cross(v1, v2)
    normal = normal / np.linalg.norm(normal)
    return normal


def calculate_normal_angles(normal):
    """Function to calculate the angle between the normal and each of the axes"""
    cos_values = []
    for axis in np.eye(3):  # x, y, z unit vectors
        cos_value = np.dot(normal, axis)
        cos_values.append(cos_value)
    return cos_values


def calculate_xy_distance(p1, p2):
    """Function to calculate the x and y distance between two points"""
    x_distance = abs(p1[0] - p2[0])
    y_distance = abs(p1[1] - p2[1])
    return x_distance, y_distance


def extract_pose_features(image, landmarks):
    """Function to extract the pose features"""
    points_sets = {
        "angle_11_12_14": (
            get_coordinates_safe(landmarks, 11),
            get_coordinates_safe(landmarks, 12),
            get_coordinates_safe(landmarks, 14),
        ),
        "angle_12_14_16": (
            get_coordinates_safe(landmarks, 12),
            get_coordinates_safe(landmarks, 11),
            get_coordinates_safe(landmarks, 13),
        ),
        "angle_11_13_15": (
            get_coordinates_safe(landmarks, 11),
            get_coordinates_safe(landmarks, 13),
            get_coordinates_safe(landmarks, 15),
        ),
        "angle_13_15_17": (
            get_coordinates_safe(landmarks, 12),
            get_coordinates_safe(landmarks, 14),
            get_coordinates_safe(landmarks, 16),
        ),
        "normal_1": (
            get_coordinates_safe(landmarks, 15),
            get_coordinates_safe(landmarks, 17),
            get_coordinates_safe(landmarks, 19),
        ),
        "normal_2": (
            get_coordinates_safe(landmarks, 16),
            get_coordinates_safe(landmarks, 18),
            get_coordinates_safe(landmarks, 20),
        ),
    }

    angles = []
    for key, (p1, p2, p3) in points_sets.items():
        if key.startswith("angle"):
            angle = calculate_angle2(p1, p2, p3)
            angles.append(angle)

    for key, (p1, p2, p3) in points_sets.items():
        if key.startswith("normal"):
            normal = calculate_normal_safe(p1, p2, p3)
            if np.array_equal(normal, [-1, -1, -1]):
                angles.extend([-1, -1, -1])
            else:
                normal_angles = calculate_normal_angles(normal)
                angles.extend(normal_angles)

    # Add the distance between points 15 (left wrist) and 16 (right wrist)
    p15 = get_coordinates_safe(landmarks, 15)
    p16 = get_coordinates_safe(landmarks, 16)
    x_distance, y_distance = calculate_xy_distance(p15, p16)
    angles.extend([x_distance, y_distance])

    return angles


def calculating_percentage(avg, all_classes):
    """Calculate percentage based on individual thresholds"""
    individual_threshold = {
        "sun": 0.9,
        "help": 0.9,
        "teacher": 0.9,
        "support": 0.9,
        "paper": 0.9,
        "love": 0.9,
        "dance": 0.9,
        "water": 0.9,
        "accident": 0.9,
        "yes": 0.9,
        "thick": 0.9,
        "high": 0.9,
        "poor": 0.9,
        "i": 0.9,
        "my": 0.9,
        "important_1": 0.9,
        "important_2": 0.9,
        "deaf": 0.9,
        "winner": 0.9,
        "eat": 0.9,
        "pizza": 0.9,
        "go": 0.9,
        "isl": 0.9,
        "friend": 0.9,
        "school": 0.9,
        "deep": 0.9,
        "loud": 0.9,
        "flat": 0.9,
        "slow": 0.9,
        "sad": 0.9,
        "soft": 0.9,
        "happy": 0.9,
        "poot": 0.9,
        "quiet": 0.9,
        "book": 0.9,
        "woman": 0.9,
    }

    threshold_percentage = []
    for i, j in zip(avg, all_classes):
        value = individual_threshold.get(j.lower(), 0.9)
        threshold_percentage.append(i * 100 / value)
    return threshold_percentage


def speak_text(text, engine):
    """Function to speak text"""
    engine.say(text)
    engine.runAndWait()


class ISLDetector:
    """Main ISL Detection class"""

    def __init__(self):
        self.left_model, self.right_model, self.pose_model = load_models()
        self.hands, self.pose, self.mp_hands, self.mp_pose = initialize_mediapipe()
        self.engine = pyttsx3.init()
        self.sentence = [""]

    def run_detection(self):
        """Main detection loop"""
        cap = cv2.VideoCapture(0)
        frame_count = 0
        accumulated_probs = None
        final_prediction_text = ""

        try:
            while True:
                ret, frame = cap.read()
                if not ret:
                    break

                # Convert the frame to RGB for MediaPipe processing
                image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = self.hands.process(image_rgb)
                results_pose = self.pose.process(image_rgb)

                # Initialize predictions and probabilities
                left_prediction, right_prediction, pose_prediction = None, None, None
                left_probs, right_probs, pose_probs = None, None, None

                # Process hand landmarks
                if results.multi_hand_landmarks:
                    for hand_landmarks, handedness in zip(
                        results.multi_hand_landmarks, results.multi_handedness
                    ):
                        label = handedness.classification[0].label
                        features = extract_features(
                            hand_landmarks.landmark,
                            (
                                results_pose.pose_landmarks.landmark
                                if results_pose.pose_landmarks
                                else None
                            ),
                        )

                        if label == "Left":
                            left_prediction = self.left_model.predict([features])[0]
                            left_probs = self.left_model.predict_proba([features])[0]
                        elif label == "Right":
                            right_prediction = self.right_model.predict([features])[0]
                            right_probs = self.right_model.predict_proba([features])[0]

                        # Draw hand landmarks
                        mp.solutions.drawing_utils.draw_landmarks(
                            frame, hand_landmarks, self.mp_hands.HAND_CONNECTIONS
                        )

                # Process pose landmarks
                if results_pose.pose_landmarks:
                    mp.solutions.drawing_utils.draw_landmarks(
                        frame,
                        results_pose.pose_landmarks,
                        self.mp_pose.POSE_CONNECTIONS,
                    )
                    pose_landmarks = results_pose.pose_landmarks.landmark
                    pose_features = extract_pose_features(frame, pose_landmarks)
                    pose_prediction = self.pose_model.predict([pose_features])[0]
                    pose_probs = self.pose_model.predict_proba([pose_features])[0]

                # Handle available predictions
                all_classes = sorted(
                    set(self.left_model.classes_)
                    .union(set(self.right_model.classes_))
                    .union(set(self.pose_model.classes_))
                )

                left_probs_aligned = np.zeros(len(all_classes))
                right_probs_aligned = np.zeros(len(all_classes))
                pose_probs_aligned = np.zeros(len(all_classes))

                if left_probs is not None:
                    left_prob_dict = {
                        cls: prob
                        for cls, prob in zip(self.left_model.classes_, left_probs)
                    }
                    left_probs_aligned = (
                        np.array([left_prob_dict.get(cls, 0) for cls in all_classes])
                        * 100
                    )

                if right_probs is not None:
                    right_prob_dict = {
                        cls: prob
                        for cls, prob in zip(self.right_model.classes_, right_probs)
                    }
                    right_probs_aligned = (
                        np.array([right_prob_dict.get(cls, 0) for cls in all_classes])
                        * 100
                    )

                if pose_probs is not None:
                    pose_prob_dict = {
                        cls: prob
                        for cls, prob in zip(self.pose_model.classes_, pose_probs)
                    }
                    pose_probs_aligned = (
                        np.array([pose_prob_dict.get(cls, 0) for cls in all_classes])
                        * 100
                    )

                # Compute average probabilities
                num_sources = sum(
                    prob is not None for prob in [left_probs, right_probs, pose_probs]
                )
                avg = (
                    left_probs_aligned + right_probs_aligned + pose_probs_aligned
                ) / (100 * num_sources if num_sources > 0 else 1)

                avg_probs = calculating_percentage(avg, all_classes)

                # Accumulate probabilities
                if accumulated_probs is None:
                    accumulated_probs = np.zeros_like(avg_probs)

                accumulated_probs += avg_probs
                frame_count += 1

                if frame_count == 5:
                    # After 5 frames, find the class with the highest accumulated probability
                    max_prob_index = np.argmax(accumulated_probs)
                    max_prob_class = all_classes[max_prob_index]
                    self.sentence.append(max_prob_class)

                    # Store the final prediction text
                    final_prediction_text = f"Final Prediction: {max_prob_class}, Prob: {accumulated_probs[max_prob_index]:.2f}"

                    # Reset for the next cycle
                    accumulated_probs = None
                    frame_count = 0

                # Display the final prediction permanently on the screen
                if final_prediction_text:
                    cv2.putText(
                        frame,
                        final_prediction_text,
                        (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        1,
                        (255, 0, 0),
                        2,
                    )

                # Display individual probabilities
                if accumulated_probs is not None:
                    y_offset = 60
                    for i, prob in enumerate(accumulated_probs):
                        class_name = all_classes[i]
                        cv2.putText(
                            frame,
                            f"{class_name}: {prob:.2f}",
                            (10, y_offset),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.8,
                            (0, 0, 255),
                            2,
                        )
                        y_offset += 30

                if len(self.sentence) > 5:
                    self.sentence = self.sentence[-5:]

                # Convert to speech in a separate thread
                if len(self.sentence) > 1:
                    speech_text = self.sentence[0]
                    threading.Thread(
                        target=speak_text, args=(speech_text, self.engine)
                    ).start()

                # Display the sentence
                cv2.rectangle(frame, (0, 0), (640, 40), (245, 117, 16), -1)
                cv2.putText(
                    frame,
                    f"{self.sentence})",
                    (3, 30),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1,
                    (255, 0, 0),
                    2,
                    cv2.LINE_AA,
                )

                # Show the result
                cv2.imshow("Hand and Pose Tracking", frame)

                if cv2.waitKey(1) & 0xFF == ord("q"):
                    break

        finally:
            cap.release()
            cv2.destroyAllWindows()


def main():
    """Main function to run the ISL detector"""
    print("TensorFlow version:", tf.__version__)
    print("Starting ISL Detector...")

    detector = ISLDetector()
    detector.run_detection()


if __name__ == "__main__":
    main()
