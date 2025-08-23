# Signify

ISL Translator for hard of hearing individuals.

![color svg 1 (2)](https://github.com/user-attachments/assets/93b54033-76a0-4f0b-9c9f-6a1bbe99e44e)

## Overview

Signify is an Indian Sign Language (ISL) translator designed to assist hard-of-hearing individuals by recognizing and translating 30 ISL signs using machine learning models.


## dataset
self made dataset 

## Working with the Model

Our model is currently trained on 30 ISL signs. The list of signs is as follows:
- Sun, help, teacher, support, paper, love, dance, water, accident, yes, thick, high, poor, I, important, deaf, winner, eat, pizza, go, ISL, friend, school, deep, loud, flat, slow, sad

### Key Scripts and Their Functions

* **Extract_data.py**: Extracts hand and pose features using Mediapipe and saves them into a pickle file for training.

* **Train.ipynb**: Trains a RandomForestClassifier using extracted features, evaluates the model, and saves the trained classifier.

* **Test.ipynb**: Tests the trained model on new data and evaluates its performance.

### Data Extraction

The `Extract_data.py` script processes images to extract hand and pose features using Mediapipe. The extracted features are saved into a pickle file for training.

### Training the Model

The `Train.ipynb` notebook trains a RandomForestClassifier on the extracted features. It includes steps for:
- Loading the data
- Splitting the data into training and testing sets
- Training the model
- Evaluating the model using metrics such as accuracy, confusion matrix, and feature importance
- Saving the trained model

### Testing the Model

The `Test.ipynb` notebook tests the trained model on new data. It includes:
- Loading the trained model
- Making predictions on test data
- Evaluating the model's performance

## Mobile App

- To test the app, you can install `base.apk` on your phone.
- The app is still a work in progress, and the majority of the backend functionality is not implemented yet.
- The app includes the functionality of converting words to ISL using animation for 10 words (boy, cold, work, happy, teacher, iit, homicide, book, baby, Bcom.).
