from flask import Flask, request, jsonify
import requests
import os
from urllib.parse import urlparse
from werkzeug.utils import secure_filename
import cv2
import mediapipe as mp
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Bidirectional,LSTM, Dense,Input,Flatten, GRU

from glob import glob
from pathlib import Path

from tqdm.notebook import tqdm

from numpy import  argmax, expand_dims 
import numpy as np

import utils

app = Flask(__name__)

def process_video(video_path):
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
    sentence = []
    threshold = 0.9
    sequence = [[0] * features] * (max_frames // 2) 
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    with mp_pose.Pose(min_detection_confidence=0.7, 
                            min_tracking_confidence=0.7) as pose:
        
        for i in range(total_frames):    
            ret, frame = cap.read()
            image, results = mp_utils.mediapipe_detection(frame, pose)
            
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
                
                    # 3. Text Script
                    if res[argmax(res)] > threshold:
                        if len(sentence) > 0:
                            if actions[argmax(res)] != sentence[-1]:
                                sentence.append(actions[argmax(res)])
                        else:
                            sentence.append(actions[argmax(res)])
                    
                    
                if len(sentence) > 5:
                    sentence = sentence[-5:]


            n_frames += 1

            if cv2.waitKey(10) & 0xFF == ord('q'):
                break
            
        print(sentence)
        cap.release()
        cv2.destroyAllWindows()
        return sentence

@app.route('/predict', methods=['GET','POST'])
def download_video():
    data = request.get_json()
    
    if not data or 'link' not in data:
        return jsonify({'error': 'No link provided'}), 400
    
    link = data['link']
    print(link)
    
    try:
        # Get the video content
        response = requests.get(link, stream=True)
        response.raise_for_status()
        
        os.makedirs('downloads', exist_ok=True)
        
        # Extract the video filename from the link
        parsed_url = urlparse(link)
        filename = os.path.basename(parsed_url.path)
        filename = f"downloads\{secure_filename(filename)}"
        
        # Save the video locally
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        print(f"{filename} saved")
        
        # Process the video
        prediction = process_video(filename)
        
        return jsonify({'prediction': prediction}), 200
    
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

        
if __name__ == '__main__':
    app.run(host='192.168.29.42', port=5000, debug=True)