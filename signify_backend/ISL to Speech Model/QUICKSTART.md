# ISL to Speech - Quick Start Guide

This guide will help you quickly set up and run the ISL to Speech conversion system.

## Prerequisites

Ensure you have the following installed:

- Python 3.7 or higher
- Webcam connected to your computer
- Git (optional, for cloning the repository)

## Installation

1. Clone or download the repository:
   ```
   git clone <repository-url>
   ```

2. Install required Python packages:
   ```
   pip install opencv-python mediapipe numpy pyttsx3 tensorflow
   ```

## Running the Application

1. Navigate to the project directory:
   ```
   cd path/to/ISL-TO-SPEECH
   ```

2. Launch Jupyter Notebook:
   ```
   jupyter notebook
   ```

3. Open `test.ipynb` in the Jupyter Notebook interface

4. Run all cells in the notebook (Cell > Run All or use Shift+Enter to run each cell)

5. When the webcam window appears, position yourself in the frame

6. Perform Indian Sign Language gestures

7. The system will:
   - Display recognized signs on screen
   - Speak the recognized signs through your computer's speakers
   - Show probabilities for different possible interpretations

8. Press 'q' to exit the application

## Troubleshooting

### Camera Not Working
- Ensure your webcam is properly connected
- Check if other applications are using the webcam
- Try specifying a different camera index in the code: `cap = cv2.VideoCapture(1)` (instead of 0)

### Model Loading Errors
- Verify that model files are in the correct location: `Model31/` directory
- Check file permissions if you're getting access errors

### Recognition Issues
- Ensure adequate lighting in your environment
- Position yourself with good contrast against the background
- Try to keep your gestures clear and within frame
- Make sure your hands are fully visible to the camera

### Speech Not Working
- Check your computer's audio settings
- Verify that pyttsx3 is installed correctly
- Try reinstalling the pyttsx3 package: `pip install --force-reinstall pyttsx3`

## Additional Resources

- [MediaPipe Documentation](https://google.github.io/mediapipe/)
- [Indian Sign Language Dictionary](https://indiansignlanguage.org/)
- See `TECHNICAL_DOCS.md` for detailed technical information

## Contact

For support or feedback, please contact the project maintainers at:
- Email: [project-email]
- GitHub Issues: [repository-issues-url]
