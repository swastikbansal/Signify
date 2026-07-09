# 🌟 Signify: Indian Sign Language (ISL) Browser Extension

![Manifest V3](https://img.shields.io/badge/Manifest-V3-brightgreen.svg)
![Three.js](https://img.shields.io/badge/Render-Three.js-orange.svg)
![Supabase](https://img.shields.io/badge/Cloud-Supabase-blueviolet.svg)
![Version](https://img.shields.io/badge/Version-2.7.0-blue.svg)

**Signify** is a powerful, state-of-the-art browser extension designed to bridge the accessibility gap for the Deaf and Hard of Hearing community in India. By utilizing advanced real-time 3D animation technology, Signify translates spoken and written text—as well as YouTube video subtitles—into **Indian Sign Language (ISL)** using a web-rendered, interactive 3D avatar.

---

## 🚀 Key Features

### 🎬 1. Seamless YouTube Integration & Sync
Signify automatically detects when you are on a YouTube watch page:
* **Interactive Transcript Extraction:** Instantly triggers YouTube’s transcript viewer, parses the timed captions segment-by-segment, and maps each spoken word to its precise timeline coordinate.
* **Timeline Synchronization:** The 3D avatar plays the corresponding signs in real-time sync with the video playback. Pausing or scrubbing the video automatically pauses or jumps the avatar's performance.
* **Auto-Start Preference:** Configurable behavior to automatically launch the translator interface when a new video starts.
* **Unified UI Injection:** Integrates a custom sign-language dashboard overlay directly on the YouTube page, with a flashing active-word highlight bar.

### 🤖 2. Interactive WebGL-Powered 3D Avatar
Driven by a customized **Three.js** animation pipeline:
* **Natural Blending & Crossfading:** Uses a sequential transition engine with fine-tuned parameters (`overlapSeconds: 0.18s`, `fadePortion: 0.18`) to smoothly blend and crossfade consecutive gestures, avoiding mechanical, abrupt jerks.
* **Adaptive Speed:** Plays animations at an optimized 1.25x speed multiplier to maintain natural synchronization with spoken and written English.
* **Lookahead Preloading:** Preloads up to 4 upcoming words ahead of time in the playback pipeline to prevent network delays and lag.
* **Camera Controls:** Supports zoom (scroll wheel) and orbit rotation (left-click drag) to allow viewers to inspect signs from different angles.

### 🎨 3. Sleek, Customizable Transparency Controls
* **Premium Glassmorphism Overlay:** Integrates a hardware-accelerated `backdrop-filter: blur(4px)` layout.
* **Custom Alpha Slider:** Adjust the opacity of the avatar panel container from 0% (fully transparent floating model) to 100% (solid background container) via the popup.

### 💾 4. Persistent Viewer Layout
* **Draggable & Resizable Panel:** Reposition the viewer container anywhere on your browser window, and scale it to your preferred size.
* **Saved Sessions:** Signify remembers your exact screen coordinate positions and dimensions across refreshes and website navigations using Chrome Storage.

### 🌐 5. Dynamic Cloud Storage (Supabase)
* **Cloud-First Vocabulary:** Resolves animations from a remote **Supabase Storage** bucket. This allows the dictionary to grow dynamically over time without requiring users to reinstall or update the extension.
* **Robust Fallback:** If the database credentials are not configured or if a word is missing from the remote bucket, Signify seamlessly falls back to local assets (`animation/` folder) and a default standby animation clip.

---

## 🛠️ Tech Stack

* **Core Logic:** JavaScript (ES6+), Chrome Extensions API (Manifest V3)
* **3D Rendering Engine:** Three.js (WebGL, `GLTFLoader.js` for 3D GLTF models, `OrbitControls.js` for camera orbit/panning)
* **Backend Database & Storage:** Supabase (Remote Storage Bucket APIs)
* **Styling System:** CSS3 (Variable themes, Responsive grids, CSS keyframe animations, Glassmorphism layouts)

---

## 📂 Repository File Structure

```bash
├── manifest.json         # Extension configuration, permissions, content script injection settings
├── content.js            # Injected script managing the WebGL scene, transcript parsing, and video sync
├── styles.css            # Stylesheets for the injected 3D container, handles, and YouTube dashboard
├── popup.html / popup.js # Browser toolbar popup overlay: handles auto-start, transparency, and favorite sites
├── sidepanel.html / .js  # Side panel translator companion app
├── supabase-config.js    # Interface code to initialize and retrieve assets from Supabase Storage buckets
├── config.js             # Local environment keys (Supabase API URL and Anon API key)
├── config.example.js     # Template for setting up custom Supabase configuration keys
├── help.html             # Rich, localized interactive guide and troubleshooting documentation
├── animation/            # Folder containing packaged local fallbacks (e.g., default.glb)
└── icons/                # Extension branding icons and SVGs
```

---

## 📥 Installation Guide

1. **Download / Clone the Repository:** Extract the extension folder to your local machine.
2. **Open Extensions Page:** Open Google Chrome and navigate to `chrome://extensions/`.
3. **Enable Developer Mode:** Toggle the **Developer mode** switch in the top-right corner.
4. **Load Unpacked:** Click the **Load unpacked** button in the top-left.
5. **Select Folder:** Select the project root folder (containing `manifest.json`).
6. *(Optional)* **Pin the Extension:** Click the extensions puzzle icon in the Chrome toolbar and pin **Signify** for quick access.

---

## ⚙️ Configuration & Supabase Setup

Signify works out-of-the-box using built-in default models, but it is highly recommended to configure your own **Supabase** backend to expand the vocabulary dynamically:

1. Create a Supabase project.
2. Go to **Storage** in the Supabase Dashboard and create a new bucket named `animations`. Make sure this bucket is public (or configure signed URLs).
3. Copy your project's **Project URL** and **API Anon Key**.
4. Rename `config.example.js` to `config.js` and paste your credentials:
   ```javascript
   (function () {
     window.ENV = {
       supabaseUrl: 'YOUR_SUPABASE_PROJECT_URL',
       supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY'
     };
   })();
   ```
5. Upload `.glb` 3D animation models named after the words they represent (e.g., `happy.glb`, `drink.glb`, `book.glb`) into your bucket.

---

## 📖 How to Use

### A. General Text-to-Sign Translation
1. Click the **Signify** icon in the browser toolbar to open the control panel.
2. Enter a custom sentence (e.g., `"happy boy drink"`) in the text field.
3. Click **Show Viewer** to load the 3D avatar on the current web page.
4. The avatar will immediately play the sign animations sequentially.

### B. YouTube Real-Time Captions
1. Open any YouTube watch page (e.g., `youtube.com/watch?v=...`).
2. Click the **Signify** toggle button injected near the YouTube player.
3. Signify will open the transcript, extract the text, and render the floating 3D avatar.
4. Play the video—the avatar will translate the audio into sign language dynamically!

---

## 🔧 Troubleshooting

* **Viewer Not Showing Up?** Ensure the webpage is fully loaded and you are not on a protected browser page (like `chrome://` settings or Chrome Web Store). Try refreshing the page.
* **Missing Word Animations?** If the avatar returns to a standby default pose, it means that the word is not yet in the Supabase bucket or local `animation/` vocabulary list.
* **Performance Lag?** Adjust your YouTube video quality or close background resource-heavy browser tabs. WebGL requires active hardware acceleration.

---

## 💙 About Indian Sign Language (ISL)

Indian Sign Language (ISL) is the primary mode of visual communication for millions of deaf and hard-of-hearing individuals across India. Unlike spoken languages, it relies on handshapes, movements, expressions, and spatial coordinates. Signify aims to democratize accessibility on the web by converting text and media content into authentic, easily understood 3D sign visualizations.

*Developed with care by **Philosia**.*
