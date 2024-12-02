# import mediapipe as mp
import numpy as np
import cv2

class MediapipeUtils:
    """This class is a utility class for mediapipe containing all the required functions for mediapipe"""
    def __init__(self,mp_holistic,mp_drawing):
        self.mp_holistic = mp_holistic
        self.mp_drawing = mp_drawing

    def mediapipe_detection(self,image, model) -> tuple:
        image_ = cv2.cvtColor(image, cv2.COLOR_BGR2RGB) 
        image_.flags.writeable = False                  
        results = model.process(image_) 
        image_.flags.writeable = True                   
        image = cv2.cvtColor(image_, cv2.COLOR_RGB2BGR) 
        return image, results

    def extract_keypoints(self,results) -> np.array:        
        pose = np.array([[res.x, res.y, res.z, res.visibility] for res in results.pose_landmarks.landmark]).flatten() if results.pose_landmarks else np.zeros(33*4)
        # face = np.array([[res.x, res.y, res.z] for res in results.face_landmarks.landmark]).flatten() if results.face_landmarks else np.zeros(468*3)
        # lh = np.array([[res.x, res.y, res.z] for res in results.left_hand_landmarks.landmark]).flatten() if results.left_hand_landmarks else np.zeros(21*3)
        # rh = np.array([[res.x, res.y, res.z] for res in results.right_hand_landmarks.landmark]).flatten() if results.right_hand_landmarks else np.zeros(21*3)
        # return np.concatenate([pose, lh, rh])    
        return pose    

    def draw_styled_landmarks(self,image, results) -> None:
        # Draw pose connections
        self.mp_drawing.draw_landmarks(image, results.pose_landmarks, self.mp_holistic.POSE_CONNECTIONS,
                                self.mp_drawing.DrawingSpec(color=(80,22,10), thickness=2, circle_radius=4), 
                                self.mp_drawing.DrawingSpec(color=(80,44,121), thickness=2, circle_radius=2)
                                ) 
        
        # Draw left hand connections
        # self.mp_drawing.draw_landmarks(image, results.left_hand_landmarks, self.mp_holistic.HAND_CONNECTIONS, 
        #                         self.mp_drawing.DrawingSpec(color=(121,22,76), thickness=2, circle_radius=4), 
        #                         self.mp_drawing.DrawingSpec(color=(121,44,250), thickness=2, circle_radius=2)
        #                         ) 
        
        # # Draw right hand connections  
        # self.mp_drawing.draw_landmarks(image, results.right_hand_landmarks, self.mp_holistic.HAND_CONNECTIONS, 
        #                         self.mp_drawing.DrawingSpec(color=(245,117,66), thickness=2, circle_radius=4), 
        #                         self.mp_drawing.DrawingSpec(color=(245,66,230), thickness=2, circle_radius=2)
        #                         ) 