# Signify 🤟

<div align="center">
  <img src="assets/images/Signify_Big_Transparent_(1).png" alt="Signify Logo" width="300"/>
  
  **Bridging Communication Through Technology**
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
</div>

---

## 📖 Table of Contents

- [About](#about)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Screenshots](#screenshots)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

---

## 🚀 About

**Signify** is a revolutionary Flutter application designed to break down communication barriers between the deaf/hard-of-hearing community and hearing individuals. The app provides bidirectional, real-time, multilingual sign language recognition and translation, making communication more accessible and inclusive.

### 🎯 Purpose

In a world where effective communication is essential, Signify serves as a digital bridge, empowering users to:

- Convert sign language gestures to text and speech
- Translate text to sign language animations
- Foster inclusive communication in various settings
- Support multiple languages and sign language variants

---

## ✨ Features

### 🎥 **Video-to-Text Conversion**

- Real-time video capture and processing
- Advanced gesture recognition using AI/ML models
- Multi-language support for sign language variants
- High accuracy text output

### 📝 **Text-to-Sign Translation**

- Convert written text to sign language animations
- 3D animated sign language demonstrations
- Support for complex sentences and phrases
- Customizable animation speed and style

### 🔍 **Optical Character Recognition (OCR)**

- Extract text from images and documents
- Google ML Kit integration for high accuracy
- Support for multiple languages
- Real-time text recognition

### 🌐 **Cloud Integration**

- Secure data storage with Supabase
- Firebase configuration management
- Google Drive API integration
- Scalable backend infrastructure

### 📱 **User Experience**

- Intuitive, accessible interface design
- Offline capabilities for basic functions
- Cross-platform compatibility (iOS & Android)
- Dark/light theme support

---

## 🛠 Tech Stack

### **Frontend (Client)**

- **Framework**: Flutter (Dart)
- **ML/Vision**: Google ML Kit (Text Recognition/OCR)
- **3D Animation**: Model Viewer Plus
- **Camera**: Camera Plugin
- **Navigation**: Go Router
- **State Management**: Flutter built-in

### **Backend Services**

- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **ML Processing**: Python-based API
- **Cloud Functions**: Supabase Edge Functions

### **Development Tools**

- **IDE**: Android Studio / VS Code
- **Version Control**: Git
- **CI/CD**: GitHub Actions (planned)
- **Testing**: Flutter Test Framework

---

## 🏗 Architecture

Signify follows a clean client-server architecture with clear separation of concerns:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│                 │    │                  │    │                 │
│  Flutter Client │◄──►│  Backend API     │◄──►│  ML/AI Models   │
│                 │    │                  │    │                 │
│  - UI/UX        │    │  - Video Processing    │  - Sign Language│
│  - Camera       │    │  - ML Inference  │    │    Recognition  │
│  - OCR (Local)  │    │  - Data Storage  │    │  - Translation  │
│  - 3D Animation │    │  - Authentication│    │  - NLP Pipeline │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### **Data Flow**

1. **Client captures video** frames using device camera
2. **Frames are sent** to backend API for ML processing
3. **Backend processes** video through AI/ML models
4. **Results are returned** to client as text/translations
5. **Client displays** results and generates 3D animations

> **Note**: Only OCR (text recognition) is performed on-device using Google ML Kit. All sign language recognition and translation ML processing occurs on the backend for optimal performance and accuracy.

---

## 📦 Installation

### **Prerequisites**

- Flutter SDK (≥3.9.0)
- Dart SDK (≥3.0.0)
- Android Studio / Xcode
- Git

### **Clone Repository**

```bash
git clone https://github.com/yourusername/signify.git
cd signify
```

### **Install Dependencies**

```bash
flutter pub get
```

### **Firebase Setup**

1. Create a new Firebase project
2. Add your `google-services.json` (Android) to `android/app/`
3. Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
4. Configure Firebase Auth and Storage

### **Supabase Configuration**

1. Create a Supabase project
2. Update API keys in your environment configuration
3. Set up database tables as per schema documentation

### **Run Application**

```bash
# Debug mode
flutter run

# Release mode (Android)
flutter build apk --release

# Release mode (iOS)
flutter build ios --release
```

---

## 🎮 Usage

### **Getting Started**

1. **Launch the app** on your device
2. **Grant permissions** for camera and microphone access
3. **Create an account** or sign in with existing credentials
4. **Choose your preferred language** and sign language variant

### **Video-to-Text Translation**

1. Tap the **"Video to Text"** option
2. Position yourself in front of the camera
3. Perform sign language gestures
4. View real-time text translation
5. Save or share the translated text

### **Text-to-Sign Translation**

1. Select **"Text to Sign"** mode
2. Type or paste text into the input field
3. Tap **"Translate"** to generate sign language animation
4. Watch the 3D animated demonstration
5. Adjust playback speed as needed

### **OCR Text Recognition**

1. Navigate to **"Text Scanner"**
2. Point camera at text or upload an image
3. Tap to capture and extract text
4. Edit or translate the recognized text

---

## 📸 Screenshots

> **Coming Soon**: Screenshots and demo videos will be added to showcase the app's interface and functionality.

<div align="center">
  <img src="assets/images/screenshot_placeholder.png" alt="Home Screen" width="250"/>
  <img src="assets/images/screenshot_placeholder.png" alt="Video Translation" width="250"/>
  <img src="assets/images/screenshot_placeholder.png" alt="3D Animation" width="250"/>
</div>

---

## 🔌 API Reference

### **Backend Endpoints**

#### **Video Processing**

```http
POST /api/v1/process-video
Content-Type: multipart/form-data

Parameters:
- video_frames: File[] (Video frames for processing)
- language: string (Target language code)
- user_id: string (User identifier)
```

#### **Text Translation**

```http
POST /api/v1/translate-text
Content-Type: application/json

Body:
{
  "text": "Hello, how are you?",
  "target_sign_language": "ASL",
  "user_id": "user123"
}
```

### **Response Format**

```json
{
  "success": true,
  "data": {
    "translation": "Translated text",
    "confidence": 0.95,
    "timestamp": "2024-01-15T10:30:00Z"
  },
  "error": null
}
```

---

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) before getting started.

### **Development Process**

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### **Code Standards**

- Follow [Flutter Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Write comprehensive unit tests
- Maintain 80%+ code coverage
- Use meaningful commit messages
- Update documentation for new features

### **Bug Reports**

Please use our [Issue Template](ISSUE_TEMPLATE.md) when reporting bugs. Include:

- Device information
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or logs

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Signify Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Acknowledgments

### **Open Source Libraries**

- [Flutter](https://flutter.dev) - UI framework
- [Google ML Kit](https://developers.google.com/ml-kit) - On-device ML
- [Supabase](https://supabase.com) - Backend infrastructure
- [Firebase](https://firebase.google.com) - Authentication and storage

### **Research & Data**

- Sign language datasets from academic institutions
- AI/ML research from the accessibility community
- User feedback from deaf and hard-of-hearing beta testers

### **Special Thanks**

- The global deaf and hard-of-hearing community for invaluable feedback
- Open source contributors who made this project possible
- Academic researchers in sign language recognition

---

<div align="center">
  <p><strong>Made with ❤️ for a more inclusive world</strong></p>
  
  [⬆️ Back to Top](#signify-)
</div>
