# ISL to Speech - Technical Documentation

## Code Implementation Details

This document provides a detailed technical explanation of the ISL to Speech conversion system implementation.

## Core Components

### 1. Feature Extraction

#### Hand Feature Extraction (`extract_features` function)
```python
def extract_features(hand_landmarks, pose_landmarks=None):
```

This function extracts features from hand landmarks detected by MediaPipe:

- **Finger Vector Analysis**: Calculates vectors for each finger joint pair and their angles with the x, y, and z axes
- **Palm Orientation**: Computes the normal vector to the palm plane and its angles with coordinate axes
- **Spatial Context**: Measures the distance between the wrist and nose (when pose data is available)

Key components:
- Uses 6 hand landmark pairs for angle calculations
- Computes angles using cosine similarity via `calculate_angle1` function
- Extracts a total of 21 features per hand (plus additional spatial context features)

#### Pose Feature Extraction (`extract_pose_features` function)
```python
def extract_pose_features(image, landmarks):
```

This function extracts features from body pose landmarks:

- **Joint Angles**: Measures angles between key joints such as shoulders, elbows, and wrists
- **Plane Normals**: Calculates normal vectors of planes formed by triplets of landmarks
- **Spatial Measurements**: Computes the distance between left and right wrists

Key components:
- Works with 6 sets of points defined in the `points_sets` dictionary
- Safely handles missing landmarks through the `get_coordinates_safe` function
- Outputs a feature vector containing angles and spatial measurements

### 2. Model Loading and Inference

```python
# Load pre-trained models from pickle files
left_model_filename = r"Model31\left_model.p"
right_model_filename = r"Model31\right_model.p"
pose_model_filename = r"Model31\pose_model.p"
```

The system loads three pre-trained machine learning models:
- Left hand gesture model
- Right hand gesture model 
- Body pose model

Each model takes its respective feature vector as input and outputs:
- Predicted class label (the recognized sign)
- Probability distribution across all possible classes

### 3. Real-time Processing Loop

The main processing loop:
1. Captures frames from the webcam
2. Detects hand and pose landmarks using MediaPipe
3. Extracts features from detected landmarks
4. Obtains predictions from all three models
5. Aligns and combines predictions
6. Accumulates predictions over multiple frames (5 frames)
7. Determines the most likely sign based on accumulated probabilities
8. Converts the recognized sign to speech using pyttsx3
9. Provides visual feedback by displaying:
   - The recognized sign
   - Probabilities for different signs
   - The sequence of recognized signs

### 4. Multi-modal Fusion

The system combines predictions from three sources:

```python
# Compute average probabilities using available predictions
num_sources = sum(prob is not None for prob in [left_probs, right_probs, pose_probs])
avg = (left_probs_aligned + right_probs_aligned + pose_probs_aligned) / (
    100 * num_sources if num_sources > 0 else 1
)
```

Key aspects:
- Aligns probability distributions from different models to the same set of classes
- Handles cases where not all models can make a prediction (e.g., when only one hand is visible)
- Uses a custom `calulating_percentage` function that applies class-specific thresholds

### 5. Speech Synthesis

```python
# Initialize the text-to-speech engine
engine = pyttsx3.init()

def speak_text(text):
    engine.say(text)
    engine.runAndWait()
```

Speech synthesis is performed:
- In a separate thread to avoid blocking the main processing loop
- After a sign has been confidently recognized
- Using the pyttsx3 library, which provides platform-independent text-to-speech capabilities

## Implementation Challenges and Solutions

### 1. Handling Missing Landmarks

The system implements robust error handling for cases where landmarks cannot be reliably detected:

```python
def get_coordinates_safe(landmark, index):
    try:
        return np.array([landmark[index].x, landmark[index].y, landmark[index].z])
    except IndexError:
        return np.array([-1, -1, -1])
```

This function safely extracts coordinates or returns default values if landmarks are missing.

### 2. Multi-frame Decision Making

To reduce noise and improve stability, the system accumulates predictions over multiple frames:

```python
if frame_count == 5:
    # After 5 frames, find the class with the highest accumulated probability
    max_prob_index = np.argmax(accumulated_probs)
    max_prob_class = all_classes[max_prob_index]
    sentence.append(max_prob_class)
```

### 3. Class-specific Thresholds

The system applies class-specific thresholds to handle variations in recognition difficulty:

```python
def calulating_percentage(avg, all_classes):
    individual_threshold = {
        "sun": 0.9,
        "help": 0.9,
        # ... other classes ...
    }
    # ...
```

## Algorithmic Details

### Angle Calculation

The system uses cosine similarity to calculate angles between vectors:

```python
def calculate_angle1(vec1, vec2):
    dot_product = np.dot(vec1, vec2)
    norm_vec1 = np.linalg.norm(vec1)
    norm_vec2 = np.linalg.norm(vec2)
    cosine_angle = dot_product / (norm_vec1 * norm_vec2)
    return cosine_angle
```

### Normal Vector Calculation

For calculating the normal vector to a plane formed by three points:

```python
def calculate_normal(p1, p2, p3):
    # Vectors on the plane
    v1 = p2 - p1
    v2 = p3 - p1
    
    # Cross product gives the normal vector
    normal = np.cross(v1, v2)
    
    # Normalize the normal vector
    normal = normal / np.linalg.norm(normal)
    
    return normal
```

## Performance Considerations

- The system processes frames in real-time at standard webcam frame rates
- Feature extraction and model inference are computationally efficient operations
- Multi-threading is used for speech synthesis to maintain processing smoothness
- A fixed window of 5 frames is used for temporal aggregation, balancing responsiveness and stability
