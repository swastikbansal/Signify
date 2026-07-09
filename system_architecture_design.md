# Signify App - System Architecture Design Document

## Overview

This document outlines the system architecture for the Signify app - a bidirectional real-time multilingual sign language recognition and translation application.

## Architecture Components

### 1. Frontend Layer (Flutter)

- **Platform**: Cross-platform (Android, iOS, Web)
- **Framework**: Flutter 3.9.0+
- **Key Features**:
  - Voice to Sign Language conversion
  - Sign Language to Voice conversion
  - ISL Dictionary
  - User Authentication
  - Real-time camera processing
  - 3D model viewer for sign animations

### 2. Authentication Services

- **Primary**: Firebase Authentication
- **Secondary**: Supabase Auth
- **Providers**: Google Sign-In, Apple Sign-In, Email/Password
- **Features**: Multi-factor authentication, social logins

### 3. Backend Services Layer

#### Firebase Services:

- **Firestore**: User data, preferences, sign language dictionary
- **Firebase Storage**: Media files, videos, images
- **Firebase Analytics**: User behavior tracking
- **Firebase Crashlytics**: Error monitoring
- **Firebase Performance**: App performance monitoring
- **Firebase Functions**: Serverless functions for business logic

#### Supabase Services:

- **PostgreSQL Database**: Advanced queries, user-generated content
- **Supabase Storage**: ML model storage, training datasets
- **Real-time subscriptions**: Live updates

### 4. Machine Learning Pipeline

#### Core ML Components:

- **MediaPipe**: Hand and pose landmark detection
- **RandomForest Models**:
  - Left hand gesture classifier
  - Right hand gesture classifier
  - Pose classifier
- **Custom Training System**: User-specific model training
- **Feature Extraction**: Hand landmarks, pose features, angles

#### ML API Server (Python/Flask):

- **Endpoints**:
  - `/processFrame` - Real-time frame processing
  - `/customTrain` - Custom model training
  - `/switchModel` - Model switching
  - `/reset` - Reset accumulation
  - `/health` - Health monitoring

### 5. External Services

- **Google ML Kit**: Text recognition, translation
- **TTS (Text-to-Speech)**: Voice output
- **STT (Speech-to-Text)**: Voice input

### 6. Data Storage Architecture

#### Assets:

- Videos, audios, images, fonts
- 3D models (.glb format)
- Rive animations
- JSON configurations
- PDF documents

#### Models:

- Pre-trained ISL models (30 signs)
- Custom user models
- Model analytics and metadata

### 7. Supported Sign Language Vocabulary

Currently supports 30 ISL signs:

- Basic: Sun, help, teacher, support, paper, love, dance, water
- Actions: accident, yes, eat, go, dance
- Descriptive: thick, high, poor, important, deaf, winner, deep, loud, flat, slow, sad
- Educational: ISL, friend, school, pizza

### 8. Localization Support

- Languages: English, Hindi, Bengali, Marathi, Telugu, Gujarati, Punjabi, Kannada
- Multi-language UI support
- Regional sign language variations

## Data Flow Architecture

1. **Input Processing**:

   - Camera feed → MediaPipe → Feature extraction
   - Voice input → Speech-to-text → Text processing

2. **ML Processing**:

   - Features → ML models → Predictions
   - Probability accumulation → Final prediction
   - Model switching (Default/Custom)

3. **Output Generation**:
   - Sign prediction → 3D animation
   - Text → Text-to-speech → Audio output
   - Results → UI display

## Security & Performance

### Security:

- Firebase App Check for API security
- Secure credential management
- Environment-based configuration
- Error handling and crash reporting

### Performance:

- Frame processing optimization
- Model caching and preloading
- Background processing
- Memory management
- Network optimization

## Development & Deployment

### Technology Stack:

- **Frontend**: Flutter/Dart
- **Backend**: Firebase, Supabase
- **ML**: Python, scikit-learn, MediaPipe
- **API**: Flask
- **Database**: Firestore, PostgreSQL
- **Storage**: Firebase Storage, Supabase Storage

### Build & Deployment:

- Android: Gradle build system
- iOS: Xcode build system
- Web: Flutter Web
- ML API: Python Flask server

This architecture supports real-time bidirectional sign language translation with custom user training capabilities and multi-platform deployment.
