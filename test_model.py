from pathlib import Path
import numpy as np
import os
from matplotlib import pyplot as plt
import time

import cv2
import mediapipe as mp
from numpy import concatenate, argmax, array, expand_dims, zeros
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Bidirectional,LSTM, Dense,Input,Flatten
from tensorflow.keras.callbacks import TensorBoard

import mp_helperfunc as mp_hf
import requests
from glob import glob

# 'q' to exit
class Model:
    def execute(self):
        # print("model")
        mp_holistic = mp.solutions.holistic  # Holistic model
        mp_drawing = mp.solutions.drawing_utils  # Drawing utilities

        def draw_landmarks(image, results):
            mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)
            mp_drawing.draw_landmarks(image, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS)
            mp_drawing.draw_landmarks(image, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS)

        DATA_PATH = os.path.join('MP_Data')

        # Labels for data
        actions = array([(i.split("\\")[-1]).split(" ")[1:] for i in glob('MP_Data\*')])
        # actions = array(['hello', 'thanks', 'iloveyou'])

        # log_dir = os.path.join('Logs')
        # tb_callback = TensorBoard(log_dir=log_dir)

        # Defining Model
        input_shape = (154, 1662)
        num_classes =  50
            
        model = Sequential([        
                Input(shape=input_shape),        
                
                # Bidirectional LSTM layers
                Bidirectional(LSTM(64, return_sequences=True)),
                Bidirectional(LSTM(128, return_sequences=True)),
                Bidirectional(LSTM(64, return_sequences=True)),
                
                # Flatten the output
                Flatten(),
                
                # Fully connected layer
                Dense(128, activation='relu'),
                Dense(num_classes, activation='softmax')
        ])

        # Loading model weights
        model_path = Path(__file__).parent / 'INCLUDE_50_V3.keras'
        model.load_weights(str(model_path))

        # 1. New detection variables
        sequence = []
        sentence = []
        threshold = 0.9

        # cap = cv2.VideoCapture(0) # Default camera
        cap = cv2.VideoCapture(0) # Secondary camera (Phone camera)
        
        with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
            while cap.isOpened():

                ret, frame = cap.read()

                # Make detections
                image, results = mp_hf.mediapipe_detection(frame, holistic)

                mp_hf.draw_styled_landmarks(image, results)

                # 2. Prediction logic
                keypoints = mp_hf.extract_keypoints(results)
                sequence.append(keypoints)
                sequence = sequence[-30:]

                if len(sequence) == 30:
                    res = model.predict(expand_dims(sequence, axis=0))[0]
                    # print(actions[np.argmax(res)])

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

                if cv2.waitKey(10) & 0xFF == ord('q'):
                    break

            cap.release()
            cv2.destroyAllWindows()


model = Model()
model.execute()