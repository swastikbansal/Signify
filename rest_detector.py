import time
import numpy as np
import mediapipe as mp
import cv2

# Rest detection parameters (tweak these for your camera/subject)
REST_SPEED_THRESHOLD = 90.0   # pixels/second; lower => more sensitive to rest
MIN_POINTS_FOR_REST = 2       # min no. of tracked points required to decide rest
REQUIRED_CONSECUTIVE_FRAMES = 3  # consecutive low-speed frames required for single-point rest

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

def _landmark_to_pixel(landmark, img_shape):
    """Convert normalized landmark to pixel (x,y)."""
    h, w = img_shape[0], img_shape[1]
    return np.array([landmark.x * w, landmark.y * h], dtype=float)

def is_resting(res_hands, img_shape):
    """
    Compute average speed (pixels/sec) for selected landmarks across frames.
    Returns True if movement is below REST_SPEED_THRESHOLD.
    """
    global prev_positions

    current_time = time.time()
    points = {}
    
    # Hands: get wrist landmark (index 0) if available
    if getattr(res_hands, "multi_hand_landmarks", None) and getattr(res_hands, "multi_handedness", None):
        for hand_landmarks, handedness in zip(res_hands.multi_hand_landmarks, res_hands.multi_handedness):
            label = handedness.classification[0].label
            try:
                wrist = _landmark_to_pixel(hand_landmarks.landmark[0], img_shape)
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
    if len(speeds) >= MIN_POINTS_FOR_REST:
        avg_speed = float(np.mean(speeds))
        for k in prev_positions['counters']:
            prev_positions['counters'][k] = 0 # reset counters on insufficient data
        return avg_speed < REST_SPEED_THRESHOLD

    # Case for a single hand 
    if len(speeds) == 1:
        key = next(iter(speed_map))
        speed = speed_map[key]
        if speed < REST_SPEED_THRESHOLD:
            prev_positions['counters'][key] = prev_positions['counters'].get(key, 0) + 1
            if prev_positions['counters'][key] >= REQUIRED_CONSECUTIVE_FRAMES:
                return True
            else:
                return False
        else:
            prev_positions['counters'][key] = 0
            return False

    return False



mp_hands = mp.solutions.hands
mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils

hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2,
                       min_detection_confidence=0.5, min_tracking_confidence=0.5)
pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)

cap = cv2.VideoCapture(1) 

if not cap.isOpened():
    print("Failed to open camera")
    exit(1)

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # frame = cv2.resize(frame, (640, 480))

        img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img_rgb.flags.writeable = False

        res_hands = hands.process(img_rgb)
        res_pose = pose.process(img_rgb)

        img_rgb.flags.writeable = True
        annotated = frame.copy()

        # Draw landmarks if present
        if getattr(res_hands, "multi_hand_landmarks", None):
            for hand_landmarks in res_hands.multi_hand_landmarks:
                mp_drawing.draw_landmarks(annotated, hand_landmarks, mp_hands.HAND_CONNECTIONS)

        if getattr(res_pose, "pose_landmarks", None):
            mp_drawing.draw_landmarks(annotated, res_pose.pose_landmarks, mp_pose.POSE_CONNECTIONS)
            mp_drawing.draw_landmarks(annotated, res_pose.pose_landmarks, mp_pose.POSE_CONNECTIONS)

        # Trying to detect rest using the function
        try:
            resting = is_resting(res_hands, annotated.shape)
            status_text = "Rest detected" if resting else "Movement"
            color = (0, 255, 0) if resting else (0, 0, 255)
        except Exception as e:
            status_text = f"Rest check error"
            color = (0, 255, 255)

        # Status text
        cv2.putText(annotated, status_text, (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, color, 2, cv2.LINE_AA)

        cv2.imshow("Live Preview - press 'q' to quit", annotated)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
finally:
    cap.release()
    cv2.destroyAllWindows()
    hands.close()
    pose.close()
