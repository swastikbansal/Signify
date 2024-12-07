from pathlib import Path
import numpy as np

import cv2
import mediapipe as mp
from numpy import  argmax, array, expand_dims 
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Bidirectional,LSTM, Dense,Input,Flatten, Dropout
import random

from glob import glob
import time


# 'q' to exit
class Model:
    def execute(self):
        mp_holistic = mp.solutions.holistic  
        mp_drawing = mp.solutions.drawing_utils  

        def draw_landmarks(image, results):
            mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)
            # mp_drawing.draw_landmarks(image, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS)
            # mp_drawing.draw_landmarks(image, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS)

        def mediapipe_detection(image, model) -> tuple:
            image_ = cv2.cvtColor(image, cv2.COLOR_BGR2RGB) 
            image_.flags.writeable = False                  
            results = model.process(image_) 
            image_.flags.writeable = True                   
            image = cv2.cvtColor(image_, cv2.COLOR_RGB2BGR) 
            return image, results
        
        def extract_keypoints(results) -> np.array:        
            pose = np.array([[res.x, res.y, res.z, res.visibility] for res in results.pose_landmarks.landmark]).flatten() if results.pose_landmarks else np.zeros(33*4)
            # face = np.array([[res.x, res.y, res.z] for res in results.face_landmarks.landmark]).flatten() if results.face_landmarks else np.zeros(468*3)
            lh = np.array([[res.x, res.y, res.z] for res in results.left_hand_landmarks.landmark]).flatten() if results.left_hand_landmarks else np.zeros(21*3)
            rh = np.array([[res.x, res.y, res.z] for res in results.right_hand_landmarks.landmark]).flatten() if results.right_hand_landmarks else np.zeros(21*3)
            
            return np.concatenate([pose, lh, rh])    
            # return pose    

        def draw_styled_landmarks(image, results) -> None:
            # Draw pose connections
            mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS,
                                    mp_drawing.DrawingSpec(color=(80,22,10), thickness=2, circle_radius=4), 
                                    mp_drawing.DrawingSpec(color=(80,44,121), thickness=2, circle_radius=2)
                                    ) 
            
            # Draw left hand connections
            mp_drawing.draw_landmarks(image, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS, 
                                    mp_drawing.DrawingSpec(color=(121,22,76), thickness=2, circle_radius=4), 
                                    mp_drawing.DrawingSpec(color=(121,44,250), thickness=2, circle_radius=2)
                                    ) 
            
            # Draw right hand connections  
            mp_drawing.draw_landmarks(image, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS, 
                                    mp_drawing.DrawingSpec(color=(245,117,66), thickness=2, circle_radius=4), 
                                    mp_drawing.DrawingSpec(color=(245,66,230), thickness=2, circle_radius=2)
                                    ) 
        

        # Labels for data
        actions = array([i.split("\\")[-1] for i in glob('MP_Data\*')])
        # actions = array(['Bank', 'big large', 'Bird', 'Black', 'Boy', 'Brother', 'Car', 'Cell phone', 'Court', 'Cow', 'Death', 'Dog', 'dry', 'Election', 'Fall', 'Fan', 'Father', 'Girl', 'good', 'Good Morning', 'happy', 'Hat', 'Hello', 'hot', 'House', 'I', 'it', 'long', 'loud', 'Monday', 'new', 'Paint', 'Pen', 'Priest', 'quiet', 'Red', 'Shoes', 'short', 'small little', 'Store or Shop', 'Summer', 'T-Shirt', 'Teacher', 'Thank you', 'Time', 'train ticket', 'White', 'Window', 'Year', 'you (plural)'])

        # Defining Model
        max_frames = 79
        # input_shape = (154, 1662)
        # input_shape = (79, 1662)
        # num_classes =  50
        # num_classes =  8
        # input_shape = (max_frames, 258)
        input_shape = (max_frames, 132)
        num_classes =  8
            
        model = Sequential([        
                Input(shape=input_shape),        
                
                # Bidirectional LSTM layers
                # Dropout(0.1),
                Bidirectional(LSTM(64, return_sequences=True)),
                # Dropout(0.2),
                Bidirectional(LSTM(128, return_sequences=True)),
                # Dropout(0.1),
                Bidirectional(LSTM(64, return_sequences=True)),
                
                # Dropout(0.5),
                Flatten(),
                
                # Fully connected layer : ANN
                Dense(128, activation='relu'),
                Dense(num_classes, activation='softmax')
        ])

        # Loading model weights
        model_path = Path(__file__).parent / 'Model' / 'INCLUDE_8_V3_noHands.h5'
        model.load_weights(str(model_path))

        # 1. New detection variables

        # cap = cv2.VideoCapture(0) # Default camera
        # random_Video = "recording.mp4"
        
        for i in range(20):
            sequence = []
            sentence = []
            threshold = 0.8
            
            random_Video = random.choice(glob('Dataset\*\*\*.mp4'))
            print(random_Video)
            cap = cv2.VideoCapture(random_Video) # Video file
            frames = cap.get(cv2.CAP_PROP_FRAME_COUNT)
            
            
            with mp_holistic.Holistic(min_detection_confidence=0.7, min_tracking_confidence=0.7) as holistic:
                for i in range(int(frames)):
                    ret, frame = cap.read()

                    # Make detections
                    image, results = mediapipe_detection(frame, holistic)
                    
                    draw_styled_landmarks(image, results)
                    
                    # 2. Prediction logic
                    keypoints = extract_keypoints(results)
                    sequence.append(keypoints)
                    sequence = sequence[-max_frames:]

                    cv2.rectangle(image, (0, 0), (640, 40), (245, 117, 16), -1)
                    cv2.putText(image, ' '.join(sentence), (3, 30),
                                cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)

                    cv2.imshow('OpenCV Feed', image)

                    if cv2.waitKey(10) & 0xFF == ord('q'):
                        break
                
                
                # Adding empty frames if the video is less than max_frames for pre-recorded videos
                if frames < max_frames:
                    rem_frames = max_frames - frames
                    for i in range(int(rem_frames)):
                        # sequence.append(np.zeros(258))
                        sequence.append(np.zeros(132))
                        
                res = model.predict(expand_dims(sequence, axis=0))[0]

                # 3. Text Script
                # if res[argmax(res)] > threshold:
                #     if len(sentence) > 0:
                #         if actions[argmax(res)] != sentence[-1]:
                #             sentence.append(actions[argmax(res)])
                #     else:
                sentence.append(actions[argmax(res)])
                
                
                print(sentence)
                cap.release()
                cv2.destroyAllWindows()


model = Model()
model.execute()