from pathlib import Path
import numpy as np


import cv2
import mediapipe as mp
from numpy import  argmax, array, expand_dims 
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Bidirectional,LSTM, Dense,Input,Flatten, GRU
import utils

from glob import glob
import time


# 'q' to exit

mp_holistic = mp.solutions.holistic  
mp_drawing = mp.solutions.drawing_utils  

mp_utils = utils.MediapipeUtils(mp_holistic, mp_drawing)


# Labels for data
actions = array([i.split("\\")[-1] for i in glob('MP_Data\*')])
# actions = array(['Beautiful','Blind','Deaf','happy','loud','quiet','sad','Ugly'])
# actions = array(['Bank', 'big large', 'Bird', 'Black', 'Boy', 'Brother', 'Car', 'Cell phone', 'Court', 'Cow', 'Death', 'Dog', 'dry', 'Election', 'Fall', 'Fan', 'Father', 'Girl', 'good', 'Good Morning', 'happy', 'Hat', 'Hello', 'hot', 'House', 'I', 'it', 'long', 'loud', 'Monday', 'new', 'Paint', 'Pen', 'Priest', 'quiet', 'Red', 'Shoes', 'short', 'small little', 'Store or Shop', 'Summer', 'T-Shirt', 'Teacher', 'Thank you', 'Time', 'train ticket', 'White', 'Window', 'Year', 'you (plural)'])

# Defining Model
  
# input_shape = (154, 1662)
# num_classes =  50

# input_shape = (79, 1662)
# num_classes =  8

max_frames = 30
# input_shape = (max_frames, 258)
input_shape = (max_frames, 132)
num_classes =  len(actions)

# Loading Model    
# model = Sequential([        
#         Input(shape=input_shape),        
        
#         GRU(64, return_sequences=True),
#         GRU(128, return_sequences=True),
#         GRU(64, return_sequences=True),
        
#         # Flatten the output
#         Flatten(),
        
#         # Fully connected layer
#         Dense(64, activation='relu'),
#         Dense(32, activation='relu'),
#         Dense(num_classes, activation='softmax')
# ])
model = Sequential([        
        Input(shape=input_shape),        
        
        # Bidirectional LSTM layers
        Bidirectional(LSTM(64, return_sequences=True)),
        Bidirectional(LSTM(128, return_sequences=True)),
        # Bidirectional(LSTM(64, return_sequences=True)),
        Bidirectional(LSTM(64, return_sequences=True)),
        
        # Flatten the output
        Flatten(),
        
        # Fully connected layer
        Dense(64, activation='relu'),
        Dense(32, activation='relu'),
        Dense(num_classes, activation='softmax')
])

model_path = Path.cwd() / 'Model' / 'INCLUDE_10_V3_clipped.h5'
model.load_weights(str(model_path))


n_frames = 0
# sequence = [[0] * 258] * (max_frames // 2) # Passing an enpty list of 258 elements to start the prediction from as soon as the input feed starts
sequence = [[0] * 132] * (max_frames // 2)
sentence = []
threshold = 0.9

cap = cv2.VideoCapture(1) # Default camera
# cap = cv2.VideoCapture("Test Recordings\\test (5).mp4")
# cap = cv2.VideoCapture("Dataset\Adjectives\\7. Deaf\MVI_9583.mp4")


with mp_holistic.Holistic(min_detection_confidence=0.7, 
                          min_tracking_confidence=0.7) as holistic:
    while cap.isOpened():    
        ret, frame = cap.read()
        
        # Make detections
        image, results = mp_utils.mediapipe_detection(frame, holistic)

        mp_utils.draw_styled_landmarks(image, results)

        keypoints = mp_utils.extract_keypoints(results)
        sequence.append(keypoints)
        
        # Predicting output in every 10 frames
        if n_frames % 5 == 0:
            sequence = sequence[-max_frames:]
                    
            # 2. Prediction logic
            if len(sequence) == max_frames:
            
                res = model.predict(expand_dims(sequence, axis=0))[0]
                # res = model.predict(sequence)   
                print(res)
                print(actions[np.argmax(res)], res[argmax(res)])

                # 3. Text Script
                if res[argmax(res)] > threshold:
                    if len(sentence) > 0:
                        if actions[argmax(res)] != sentence[-1]:
                            sentence.append(actions[argmax(res)])
                    else:
                        sentence.append(actions[argmax(res)])
                
                # res = res.remove(res[argmax(res)])
                # print(actions[np.argmax(res)], res[argmax(res)])
                
            # if len(sentence) > 5:
            #     sentence = sentence[-5:]

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


