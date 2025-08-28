import numpy as np
import json
import cv2
import pickle
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import os
from supabase import create_client, Client
from dotenv import load_dotenv
from utils import Utils


# TO DO
# Delete the images from supabase after downloading and training the model successfully
# Upload Model analytics with model
# currently its just common make it specific to each user

class Trainer:
    def __init__(self,hands,pose):
        load_dotenv()
        self.utils = Utils()
        
        self.data: list = []
        self.labels: list = []
        
        os.makedirs('./Custom_Dataset/MP_DATA', exist_ok=True)
        os.makedirs('./Custom_Dataset/Models', exist_ok=True)
        os.makedirs('./Custom_Dataset/Data', exist_ok=True)
        
        # Base paths
        self.ROOT_FOLDER: str = "./Custom_Dataset"
        self.DATA_FOLDER: str = f"{self.ROOT_FOLDER}/Data"
        self.JSON_PATH: str = f'{self.ROOT_FOLDER}/MP_DATA'
        self.MODEL_PATH: str = f'{self.ROOT_FOLDER}/Models'

        # Org Json paths
        self.LEFT_JSON: str  = r'./MP_Data/left.json'
        self.RIGHT_JSON: str = r'./MP_Data/right.json'
        self.POSE_JSON: str  = r'./MP_Data/pose.json'

        # New JSON PATHS
        self.NEW_LEFT_JSON: str  = rf'{self.JSON_PATH}/new_left.json'
        self.NEW_RIGHT_JSON: str = rf'{self.JSON_PATH}/new_right.json'
        self.NEW_POSE_JSON: str  = rf'{self.JSON_PATH}/new_pose.json'
        
        # Mediapipe
        self.hands = hands
        self.pose = pose
        
        #Supabase
        self.SUPABASE_URL: str = os.environ.get("SUPABASE_URL")
        self.SUPABASE_KEY: str = os.environ.get("SUPABASE_KEY")
        self.supabase: Client = create_client(self.SUPABASE_URL, self.SUPABASE_KEY)
        self.SUPABASE_BUCKET:str = "Custom_Dataset"
    
    def download_files(self, path: str = ""):
        """Recursively list all files in a Supabase storage bucket."""
        items = self.supabase.storage.from_(self.SUPABASE_BUCKET).list(path)
        all_files = []

        for item in items:
            # Skipping models folder
            if item["name"].lower() == "models":
                continue
            
            # Folder
            if item["metadata"] is None:  
                sub_path = f"{path}/{item['name']}" if path else item["name"]

                all_files.extend(self.download_files(sub_path))

            # File
            else:  
                file_path = f"{path}/{item['name']}" if path else item["name"]
                down_path = f"./{self.DATA_FOLDER}/{file_path}"
                os.makedirs(os.path.dirname(down_path), exist_ok=True)
                with open(rf"{down_path}", "wb+") as f:
                    response = (
                        self.supabase.storage
                        .from_(self.SUPABASE_BUCKET)
                        .download(rf"{file_path}")
                        )
                    f.write(response)
                
                all_files.append(file_path)

        return all_files

    def download_images(self):
        # Request files from the root of the bucket (empty path)
        files = self.download_files("")  
        print(f"Downloaded files: {files}")
        if not files:
            print("No files downloaded.")
        else:
            print(f"Downloaded images: {files}")
        return files
        
    def process_hand(self, hand_label:str) -> tuple:
        """Iterate through each class folder in the data directory"""
        # Reset data and labels for each hand type
        data = []
        labels = []
        
        for label in os.listdir(self.DATA_FOLDER):
            class_folder = os.path.join(self.DATA_FOLDER, label)

            if os.path.isdir(class_folder):
                # Iterate through each image in the class folder
                for image_name in os.listdir(class_folder):
                    image_path = os.path.join(class_folder, image_name)
                    
                    image = cv2.imread(image_path)
                    if image is None:
                        print(f"Warning: Could not read image {image_path}")
                        continue
                        
                    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                    results = self.hands.process(image_rgb)

                    pose_results = self.pose.process(image_rgb)

                    # If hands are detected, extract features for the specified hand
                    if results.multi_hand_landmarks:
                        for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
                            if handedness.classification[0].label == hand_label:
                                if pose_results.pose_landmarks:
                                    features = self.utils.extract_hand_features(hand_landmarks.landmark, pose_results.pose_landmarks.landmark)
                                    data.append(features)
                                    labels.append(label)

        return data, labels

    def process_pose(self):
        """
        Processes images in the data folder to extract pose features and labels.
        """
        data = []
        labels = []

        for label in os.listdir(self.DATA_FOLDER):
            class_folder = os.path.join(self.DATA_FOLDER, label)

            if os.path.isdir(class_folder):
                for image_name in os.listdir(class_folder):
                    image_path = os.path.join(class_folder, image_name)
                    
                    image = cv2.imread(image_path)
                    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                    results = self.pose.process(image_rgb)

                    if results.pose_landmarks:
                        landmarks = results.pose_landmarks.landmark
                        features = self.utils.extract_pose_features(landmarks)
                        data.append(features)
                        labels.append(label)
        
        return data, labels

    def load_json(self,json_path):
        with open(json_path, 'r') as f:
            data_dict = json.load(f)
        X = np.array(data_dict['data'])
        y = np.array(data_dict['labels'])
        return X, y

    def merge_json(self,new_data, new_labels, json_path, new_path):
        merged_data = new_data
        merged_labels = new_labels
        
        if os.path.exists(json_path):
            with open(json_path, 'r') as f:
                old = json.load(f)
            merged_data = old.get('data', []) + new_data
            merged_labels = old.get('labels', []) + new_labels

        with open(new_path, 'w') as f:
            json.dump({'data': merged_data, 'labels': merged_labels}, f)
        print(f"JSON file merged and saved at {new_path}")

    def train_model(self,new_path, model_path):
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        X, y = self.load_json(new_path)
        
        if len(X) == 0:
            raise ValueError(f"No data found for training model at {new_path}")

        # Check if we have enough samples for stratification
        unique_labels = np.unique(y)
        if len(unique_labels) < 2:
            raise ValueError(f"Need at least 2 classes for training, found {len(unique_labels)}")
            
        # Check if each class has at least 2 samples for stratification
        label_counts = np.bincount(np.array([np.where(unique_labels == label)[0][0] for label in y]))
        if np.any(label_counts < 2):
            print("Warning: Some classes have less than 2 samples, using shuffle without stratify")
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, shuffle=True
            )
        else:
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, shuffle=True, stratify=y
            )
        
        model = RandomForestClassifier(
            n_estimators=100,
            max_depth=6,
            min_samples_split=3,
            min_samples_leaf=2,
            bootstrap=True,
            criterion='entropy',
            oob_score=True
        )
        
        model.fit(X_train, y_train)
        
        y_pred = model.predict(X_test)
        acc = np.mean(y_pred == y_test)
        print(f"Accuracy for {model_path}: {acc *100 :.2f}")

        with open(model_path, 'wb') as f:
            pickle.dump({'model': model}, f)

    def compute_accuracy(self,y_true, y_pred):
        correct_predictions = sum(1 for true_label, predicted in zip(y_true, y_pred) if true_label == predicted)
        return correct_predictions / len(y_true)
    
    def upload_model(self,newModel_file):
        with open(newModel_file, "rb") as f:
            self.response = (
                self.supabase.storage
                .from_(self.SUPABASE_BUCKET)
                .upload(
                    file=f,
                    path=f"models/{os.path.basename(newModel_file)}",
                    file_options={"cache-control": "3600", "upsert": "true"}
                )
            )
            print(f"Uploaded model to Supabase: {newModel_file}")

    def delete_images(self, files):
        """
        Delete local copies and remove files from Supabase bucket.
        'files' is expected to be a list of file paths relative to the bucket root
        (the same strings produced by download_files).
        """
        for file in files:
            local_path = os.path.normpath(os.path.join(self.DATA_FOLDER, file))
            try:
                if os.path.exists(local_path):
                    os.remove(local_path)
                else:
                    print(f"Local file not found (skipping): {local_path}")
            except Exception as e:
                print(f"Failed to delete local file {local_path}: {e}")

            try:
                self.supabase.storage.from_(self.SUPABASE_BUCKET).remove([file])
            except Exception as e:
                print(f"Failed to delete remote file {file} from Supabase: {e}")

        print("Deleting images")

    def run_training(self) -> bool:
        try:
            files = self.download_images()
            
            # Extracting data
            left_data, left_labels = self.process_hand('Left')
            right_data, right_labels = self.process_hand('Right')
            pose_data, pose_labels = self.process_pose()

            # Save the data and labels in JSON file
            self.merge_json(left_data, left_labels, self.LEFT_JSON, self.NEW_LEFT_JSON)
            self.merge_json(right_data, right_labels, self.RIGHT_JSON, self.NEW_RIGHT_JSON)
            self.merge_json(pose_data, pose_labels, self.POSE_JSON, self.NEW_POSE_JSON)

            # Train and save all three models using JSON data files
            self.train_model(self.NEW_POSE_JSON, f'{self.MODEL_PATH}/pose_model_new.p')
            self.train_model(self.NEW_LEFT_JSON, f'{self.MODEL_PATH}/left_model_new.p')
            self.train_model(self.NEW_RIGHT_JSON, f'{self.MODEL_PATH}/right_model_new.p')
            
            #Upload Model
            self.upload_model(f'{self.MODEL_PATH}/pose_model_new.p')
            self.upload_model(f'{self.MODEL_PATH}/left_model_new.p')
            self.upload_model(f'{self.MODEL_PATH}/right_model_new.p')

            self.delete_images(files)

            return True

        except Exception as e:
            print(f"Training failed: {e}")
            return False