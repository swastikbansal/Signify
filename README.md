# ISL Animation Viewer Extension

A browser extension that displays Indian Sign Language (ISL) animations on any webpage.

## Features

- View ISL animations for words in sentences
- Floating viewer that can be positioned anywhere on the page
- Works on any website
- Supports multiple ISL animation models

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode" in the top right
3. Click "Load unpacked" and select this folder
4. The extension will be installed and ready to use

## Usage

1. Click on the ISL extension icon in your browser toolbar
2. Enter a sentence in the popup (e.g., "happy boy drink")
3. Click "Show Viewer" to display the animation viewer
4. The viewer will play animations for recognized words in sequence
5. Click "Hide Viewer" or the X button to close the viewer

## Available Animations

The extension includes animations for the following words:
- baby, book, boy, cold, drink, happy, teacher, work

Add more `.glb` animation files to the `animation/` folder to expand the vocabulary.

## Development

To modify the extension:
1. Edit the relevant files
2. Go to `chrome://extensions/`
3. Click the refresh button on the extension card to reload

## File Structure

- `manifest.json` - Extension configuration
- `popup.html/js` - Extension popup interface
- `content.js` - Script injected into web pages
- `styles.css` - Styles for the floating viewer
- `animation/` - ISL animation model files (.glb format)
- `icons/` - Extension icons
