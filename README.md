# Signify

ISL Translator for hard of hearing individuals.

![color svg 1 (2)](https://github.com/user-attachments/assets/93b54033-76a0-4f0b-9c9f-6a1bbe99e44e)

## Overview

Signify is an Indian Sign Language (ISL) translator designed to assist hard-of-hearing individuals by recognizing and translating ISL signs using machine learning models. The system uses MediaPipe for feature extraction and RandomForestClassifier for sign recognition.

## Installation

### Prerequisites
- Python 3.10+
- Poetry (for dependency management)

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/swastikbansal/Signify.git
   cd Signify
   ```

2. Install dependencies using Poetry:
   ```bash
   poetry install
   ```

3. Activate the virtual environment:
   ```bash
   poetry shell
   ```

## Project Structure

```
Signify/
├── Features Extraction/    # Feature extraction scripts for left hand, right hand, and pose
├── Models/                # Trained model files (left_model.p, right_model.p, pose_model.p)
├── Python Live/           # Training, testing notebooks and API implementations
├── Misc/                  # Utility scripts and model testing
├── Setup/                 # Installation requirements
├── extract_data.ipynb     # Data extraction notebook
├── api_app.py            # Main Flask API application
└── utils.py              # Utility functions
```

## Dataset

The project uses a self-made dataset of Indian Sign Language signs. The dataset includes video recordings of ISL signs which are processed to extract hand and pose features using MediaPipe. 

## Working with the Model

Our model uses separate RandomForestClassifiers for left hand, right hand, and pose recognition to provide comprehensive ISL sign detection.

### Key Scripts and Their Functions

* **Features Extraction/**: Contains scripts for extracting features from different body parts:
  - `left.py`: Extracts left hand features using MediaPipe
  - `right.py`: Extracts right hand features using MediaPipe  
  - `pose.py`: Extracts pose features using MediaPipe

* **extract_data.ipynb**: Main notebook for data extraction and preprocessing

* **Python Live/train.ipynb**: Trains RandomForestClassifier models using extracted features, evaluates performance, and saves trained models

* **Python Live/test.ipynb**: Tests the trained models on new data and evaluates performance

### Data Extraction

The feature extraction scripts process images/videos to extract hand and pose features using MediaPipe. The extracted features are saved into pickle files for training. Each body part (left hand, right hand, pose) is processed separately to create specialized models.

### Training the Model

The training notebook (`Python Live/train.ipynb`) trains separate RandomForestClassifier models for each body part. The process includes:
- Loading preprocessed feature data
- Splitting data into training and testing sets
- Training individual models for left hand, right hand, and pose
- Evaluating models using accuracy metrics and confusion matrices
- Saving trained models as pickle files in the `Models/` directory

### Testing the Model

The testing notebook (`Python Live/test.ipynb`) evaluates the trained models:
- Loading trained models from pickle files
- Making predictions on test data
- Combining predictions from multiple models for final classification
- Performance evaluation and metrics analysis

## API Usage

The project provides Flask API endpoints for real-time sign language recognition:

### Main API (api_app.py)
```bash
python api_app.py
```
- Provides endpoints for video processing and sign prediction
- Supports frame-by-frame analysis and accumulated prediction results

### Live API (Python Live/API.py)  
```bash
cd "Python Live"
python API.py
```
- Alternative API implementation with additional features
- Includes integration with external services

### API Endpoints
- `GET /`: Health check endpoint
- `POST /predict`: Process video/image data for sign prediction

## Usage

### Quick Start
1. Start the API server:
   ```bash
   python api_app.py
   ```

2. Send a POST request to `/predict` with image/video data to get sign predictions

3. For development and testing, use the notebooks in `Python Live/` directory

### Real-time Detection
Use the scripts in `Misc/` directory for real-time sign detection:
```bash
python Misc/test_model.py
```

## Mobile App

- To test the app, you can install base.apk on your phone
- The app is still a work in progress, and the majority of the backend functionality is not implemented yet  
- The app includes functionality for converting words to ISL using animations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request

## License

This project is licensed under the GNU General Public License - see the [LICENSE.txt](LICENSE.txt) file for details.