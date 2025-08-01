# Installation Guide for ISL Animation Viewer Extension

## Quick Start

1. **Open Chrome Extensions Page**
   - Go to `chrome://extensions/` in your Chrome browser
   - Or click the three dots menu → More tools → Extensions

2. **Enable Developer Mode**
   - Toggle the "Developer mode" switch in the top right corner

3. **Install the Extension**
   - Click "Load unpacked" button
   - Navigate to and select the folder containing this extension (`Test3`)
   - The extension should now appear in your extensions list

4. **Pin the Extension (Optional)**
   - Click the puzzle piece icon in the Chrome toolbar
   - Find "ISL Animation Viewer" and click the pin icon to keep it visible

## How to Use

1. **Open Any Website**
   - Navigate to any webpage where you want to use the ISL viewer

2. **Open the Extension**
   - Click the ISL extension icon in your browser toolbar
   - A popup will appear with input field and controls

3. **Enter a Sentence**
   - Type a sentence using available words (e.g., "happy boy drink")
   - Available words: baby, book, boy, cold, drink, happy, teacher, work

4. **Show the Viewer**
   - Click "Show Viewer" button
   - A floating 3D viewer will appear on the webpage
   - Animations will play automatically for recognized words

5. **Control the Viewer**
   - Use your mouse to rotate the 3D view
   - Click the "×" button or "Hide Viewer" to close
   - Enter new sentences to play different animations

## Troubleshooting

- **Extension not loading**: Make sure you selected the correct folder and that all files are present
- **Animations not playing**: Check that the animation files are in the `animation/` folder
- **Viewer not appearing**: Try refreshing the webpage and ensure the extension has permissions

## Adding More Animations

To add new ISL animations:
1. Place new `.glb` files in the `animation/` folder
2. Edit `content.js` to add the new files to the `availableModels` array
3. Reload the extension in Chrome

## Browser Compatibility

- **Chrome**: Fully supported
- **Edge**: Should work (Chromium-based)
- **Firefox**: Not supported (uses Manifest V3)
- **Safari**: Not supported
