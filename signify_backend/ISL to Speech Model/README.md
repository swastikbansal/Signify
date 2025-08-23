# ISL to Speech Conversion System

## Project Overview

This project implements an Indian Sign Language (ISL) to Speech conversion system using computer vision and machine learning techniques. The system captures sign language gestures through a webcam, processes them using machine learning models, and converts them into spoken words, enabling real-time communication between sign language users and non-signers.

## System Architecture

The system uses a multi-modal approach to recognize ISL gestures:

1. **Hand Gesture Recognition**: Tracks and analyzes both left and right hand movements and positions
2. **Body Pose Recognition**: Analyzes overall body posture to provide additional context
3. **Combined Decision Making**: Integrates predictions from all three models for more accurate results
4. **Text-to-Speech Conversion**: Converts recognized signs into spoken words

## File Structure

### Main Files

- **test.ipynb**: The main application file that:
  - Initializes video capture and model loading
  - Processes webcam input in real-time
  - Extracts features from hands and body pose
  - Makes predictions using pre-trained models
  - Converts predicted signs to speech
  - Provides visual feedback through the webcam interface

- **train.ipynb**: Contains the code used to train the machine learning models on ISL gestures dataset

### Feature Extraction Modules

- **features_extraction.py/left.py**: Module for extracting features from the left hand gestures
- **features_extraction.py/right.py**: Module for extracting features from the right hand gestures
- **features_extraction.py/pose.py**: Module for extracting features from the body pose

These modules contain specialized functions to:
- Calculate angles between joints/landmarks
- Measure distances between specific points
- Compute normal vectors of planes formed by sets of points
- Transform raw camera data into meaningful feature vectors

### Pre-trained Models

- **Model31/left_model.p**: Trained machine learning model for left hand gesture recognition
- **Model31/right_model.p**: Trained machine learning model for right hand gesture recognition
- **Model31/pose_model.p**: Trained machine learning model for body pose recognition

## Technical Implementation

### Feature Extraction

The system extracts several types of features:

1. **Hand Features**:
   - Angles between finger joints relative to coordinate axes
   - Orientation of the palm
   - Relative positions of fingers and wrist
   - Distance between hand and face

2. **Pose Features**:
   - Angles between major body joints (shoulders, elbows, wrists)
   - Orientation of planes formed by sets of points on the body
   - Distance between hands

### Model Architecture

The system uses trained classifiers that take the extracted features as input and output probabilities for each possible sign class. The models were trained on a dataset of ISL gestures covering various common words and phrases.

### Real-time Processing

The application:
1. Captures frames from the webcam
2. Processes each frame to extract hand and pose features
3. Feeds features to the pre-trained models
4. Aggregates predictions over multiple frames to reduce noise
5. Converts high-confidence predictions to speech
6. Displays visual feedback to the user

## Usage Instructions

1. Ensure you have all required dependencies installed
2. Connect a webcam to your computer
3. Run `test.ipynb` in a Jupyter Notebook environment
4. Position yourself in front of the webcam
5. Perform ISL gestures
6. The system will display recognized signs on screen and speak them aloud
7. Press 'q' to exit the application

## Dependencies

- Python 3.x
- OpenCV (cv2)
- MediaPipe
- NumPy
- PyTTSx3 (text-to-speech)
- Pickle (for loading models)
- TensorFlow (for model operations)

## Future Improvements

- Expand the vocabulary of recognized signs
- Improve recognition accuracy in varied lighting conditions
- Add support for continuous signing and sentence formation
- Develop a mobile application version
- Integrate with other accessibility tools

## Acknowledgments

This project was developed as part of the Smart India Hackathon (SIH) to improve accessibility for the deaf and hard of hearing community.
