# Develop an algo for detcting hand movement 
import cv2
import mediapipe as mp
import numpy as np

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.7,
)
mp_draw = mp.solutions.drawing_utils

# Function to calculate movement
def calculate_movement(prev_landmarks, curr_landmarks):
    if prev_landmarks is None:
        return 0
    # Calculate Euclidean distance between corresponding landmarks
    movement = 0
    for p, c in zip(prev_landmarks, curr_landmarks):
        distance = np.linalg.norm(np.array([p.x, p.y]) - np.array([c.x, c.y]))
        movement += distance
    return movement

cap = cv2.VideoCapture(0)
prev_landmarks = None
movement_threshold = 8  # movement sensitivity\

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
            # Draw hand landmarks on the image
            mp_draw.draw_landmarks(
                image, hand_landmarks, mp_hands.HAND_CONNECTIONS)
            
            # Calculate movement
            hand_movement = calculate_movement(prev_landmarks, hand_landmarks.landmark)
            prev_landmarks = hand_landmarks.landmark

    else:
        prev_landmarks = None

    # Display movement value
    cv2.putText(image, f'Movement: {hand_movement:.4f}', (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)

    # Check if movement exceeds threshold
    if hand_movement > movement_threshold:
        cv2.putText(image, 'Hand Movement Detected', (10, 70),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    cv2.imshow('Hand Movement Detection', image)

    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

hands.close()
cap.release()
cv2.destroyAllWindows()
