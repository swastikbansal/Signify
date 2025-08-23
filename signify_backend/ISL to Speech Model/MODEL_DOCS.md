# ISL to Speech - Model and Vocabulary Documentation

## Model Architecture

The ISL to Speech system uses three machine learning models to recognize Indian Sign Language gestures:

### 1. Left Hand Model (`left_model.p`)

- **Input**: 21+ dimensional feature vector representing left hand gesture features
- **Type**: Classifier model trained on left hand ISL gestures
- **Output**: Probability distribution across supported ISL sign classes

### 2. Right Hand Model (`right_model.p`)

- **Input**: 21+ dimensional feature vector representing right hand gesture features
- **Type**: Classifier model trained on right hand ISL gestures
- **Output**: Probability distribution across supported ISL sign classes

### 3. Pose Model (`pose_model.p`)

- **Input**: Feature vector representing body pose measurements
- **Type**: Classifier model trained on full body pose for ISL gestures
- **Output**: Probability distribution across supported ISL sign classes

## Supported Vocabulary

The system currently recognizes the following Indian Sign Language words/concepts:

1. **Basic Actions**
   - eat
   - dance
   - go
   - support
   - help

2. **Objects**
   - sun
   - water
   - paper
   - book
   - pizza

3. **Emotions/States**
   - happy
   - sad
   - love
   - deep
   - flat
   - thick
   - high
   - loud
   - slow
   - soft
   - quiet
   - poor

4. **Pronouns**
   - i
   - my

5. **Places**
   - school

6. **People**
   - teacher
   - friend
   - woman
   - deaf
   - winner

7. **Concepts**
   - important_1
   - important_2
   - accident
   - yes
   - isl

## Feature Representation

### Hand Features

Each hand is represented by a feature vector that captures:

1. **Finger Joint Vectors**: For each finger, the direction vector from base to tip joint
2. **Vector-Axis Angles**: The angle between each finger vector and the coordinate axes
3. **Palm Orientation**: The orientation of the palm plane in 3D space
4. **Spatial Context**: Distance between hand and face landmarks

### Pose Features

Body pose is represented by a feature vector that captures:

1. **Joint Angles**: Angles between key pairs of body joints
2. **Plane Orientations**: Orientation of planes formed by triplets of body landmarks
3. **Limb Distances**: Spatial distances between key body parts

## Model Performance

The models employ class-specific thresholds to account for varying recognition difficulty:

```python
individual_threshold = {
    "sun": 0.9,
    "help": 0.9,
    "teacher": 0.9,
    "support": 0.9,
    "paper": 0.9,
    "love": 0.9,
    "dance": 0.9,
    "water": 0.9,
    "accident": 0.9,
    "yes": 0.9,
    "thick": 0.9,
    "high": 0.9,
    "poor": 0.9,
    "i": 0.9,
    "my": 0.9,
    "important_1": 0.9,
    "important_2": 0.9,
    "deaf": 0.9,
    "winner": 0.9,
    "eat": 0.9,
    "pizza": 0.9,
    "go": 0.9,
    "isl": 0.9,
    "friend": 0.9,
    "school": 0.9,
    "deep": 0.9,
    "loud": 0.9,
    "flat": 0.9,
    "slow": 0.9,
    "sad": 0.9,
    "soft": 0.9,
    "happy": 0.9,
    "poot": 0.9,
    "quiet": 0.9,
    "book": 0.9,
    "woman": 0.9,
}
```

## Training Methodology

The models were trained on a dataset of ISL gestures captured using:
- Video recordings of native ISL signers
- Feature extraction using MediaPipe hand and pose tracking
- Class balancing to ensure even representation
- Cross-validation to tune model parameters

## Implementation Notes

1. **Multi-model Fusion**: The system averages predictions from all available models, handling cases where not all models can make predictions (e.g., when only one hand is visible)

2. **Temporal Aggregation**: Predictions are accumulated over 5 frames to reduce noise and improve stability

3. **Dynamic Thresholding**: Class-specific confidence thresholds are applied to account for varying recognition difficulty

4. **Feedback Mechanism**: The interface shows:
   - The current recognized sign
   - Recent history of recognized signs
   - Confidence scores for various candidate interpretations

## Extension Points

To extend the vocabulary:

1. Collect examples of new signs
2. Extract features using the existing feature extraction pipeline
3. Retrain the models or add additional model for the new signs
4. Update the `individual_threshold` dictionary with appropriate thresholds for new classes
