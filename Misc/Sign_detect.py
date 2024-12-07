# Develop an algo for detcting hand movement 
import cv2
import mediapipe as mp
import numpy as np
import time

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)
mp_draw = mp.solutions.drawing_utils

# Function to calculate movement
def calculate_movement(prev_landmarks, curr_landmarks):
    if prev_landmarks is None:
        return 0
    
    # Calculate Euclidean distance between corresponding landmarks
    movement = 0
    for p, c in zip(prev_landmarks, curr_landmarks):
        distance = np.linalg.norm(np.array([p.x, p.y, p.z]) - np.array([c.x, c.y, c.z]))
        movement += distance
    return movement

cap = cv2.VideoCapture("test.mp4")
# cap = cv2.VideoCapture(0)
prev_landmarks = None

while cap.isOpened():
    success, image = cap.read()
    if not success:
        break

    # Flip the image horizontally for a later selfie-view display
    image = cv2.flip(image, 1)

    # Convert the BGR image to RGB before processing
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)

    hand_movement = 0
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_draw.draw_landmarks(
                image, hand_landmarks, mp_hands.HAND_CONNECTIONS)
            
            # Calculate movement
            hand_movement = calculate_movement(prev_landmarks, hand_landmarks.landmark)
            prev_landmarks = hand_landmarks.landmark

    else:
        prev_landmarks = None

    # Display movement value and no. of hands
    cv2.putText(image, f'Movement: {hand_movement:.4f}', (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
    
    num_hands = None
    if results.multi_hand_landmarks:
        num_hands = len(results.multi_hand_landmarks)
    cv2.putText(image, f'No. of hands: {num_hands}', (10, 70),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)

    
    # Decidinf movement threshold based on number of hands
    movement_threshold = None
    if num_hands == 1 :
        movement_threshold = 0.13 
    
    if num_hands == 2 :
        movement_threshold = 4.4 
    
    # Check if movement exceeds threshold
    if num_hands:
        if hand_movement > movement_threshold:
            cv2.putText(image, 'Hand Movement Detected', (10, 110),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    image = cv2.resize(image, (500, 400))
    cv2.imshow('Hand Movement Detection', image)

    # time.sleep(0.3)
    
    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

hands.close()
cap.release()
cv2.destroyAllWindows()
