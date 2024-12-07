import cv2
import mediapipe as mp
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Bidirectional,LSTM, Dense,Input,Flatten, GRU

from glob import glob
import os
from pathlib import Path

from tqdm.notebook import tqdm

from numpy import  argmax, expand_dims 
import numpy as np

import utils

mp_pose = mp.solutions.pose  
mp_drawing = mp.solutions.drawing_utils  

mp_utils = utils.MediapipeUtils(mp_pose, mp_drawing)

# Labels for data
# actions = array([i.split("\\")[-1] for i in glob('MP_Data\*')])
actions = ['Blind','Deaf','Flat','Happy','Poor','Quiet','Rich','Sad','Slow','Thick']

# Defining Hyperparameters
max_frames = 26
features = 23
input_shape = (max_frames, features)
num_classes =  len(actions)

# Landmarks for finding angles

# Loading Model    
model = Sequential([        
        Input(shape=input_shape),        
        
        GRU(64, return_sequences=True),
        GRU(128, return_sequences=True),
        GRU(64, return_sequences=True),
        # LSTM(64, return_sequences=True),
        # LSTM(128, return_sequences=True),
        # LSTM(64, return_sequences=True),
        
        # Flatten the output
        Flatten(),
        
        # Fully connected layer
        Dense(64, activation='relu'),
        Dense(32, activation='relu'),
        Dense(num_classes, activation='softmax')
])

model_path = Path.cwd() / 'Model' / 'INCLUDE_10_V4_angled.h5'
model.load_weights(str(model_path))

n_frames = 0
sequence = [[0] * features] * (max_frames // 2) 
sentence = []
threshold = 0.9

cap = cv2.VideoCapture(1) # Default camera
# cap = cv2.VideoCapture("Test Recordings\\test (5).mp4")
# cap = cv2.VideoCapture("Dataset\Adjectives\\7. Deaf\MVI_9583.mp4")


with mp_pose.Pose(min_detection_confidence=0.7, 
                          min_tracking_confidence=0.7) as pose:
    while cap.isOpened():    
        ret, frame = cap.read()
        image, results = mp_utils.mediapipe_detection(frame, pose)
        mp_utils.draw_styled_landmarks(image, results)
        
        if results.pose_landmarks:
            results = results.pose_landmarks.landmark
            features = np.array(mp_utils.extract_features(results))
            sequence.append(features)    
        
        else:
            sequence.append(np.zeros(23))
        
        # Predicting output in every 15 frames
        if n_frames % 15 == 0:
            sequence = sequence[-max_frames:]
                    
            # 2. Prediction logic
            if len(sequence) == max_frames:
            
                res = model.predict(expand_dims(sequence, axis=0))[0]
                
                [print(j,i * 100) for i,j in zip(res,actions)]
                
                print(actions[np.argmax(res)], res[argmax(res)])

                # 3. Text Script
                if res[argmax(res)] > threshold:
                    if len(sentence) > 0:
                        if actions[argmax(res)] != sentence[-1]:
                            sentence.append(actions[argmax(res)])
                    else:
                        sentence.append(actions[argmax(res)])
                
                
            if len(sentence) > 5:
                sentence = sentence[-5:]

        cv2.rectangle(image, (0, 0), (640, 40), (245, 117, 16), -1)
        cv2.putText(image, ' '.join(sentence), (3, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)

        cv2.imshow('OpenCV Feed', image)
        n_frames += 1

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break
        
    print(sentence)
    cap.release()
    cv2.destroyAllWindows()