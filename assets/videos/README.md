# ISL Video Assets

This directory contains video files for the ISL Dictionary feature.

## Adding Videos

To add sign language videos:

1. **File Naming**: Name your video files using lowercase words matching the sign dictionary entries:
   - `happy.mp4` - for the "happy" sign
   - `child.mp4` - for the "child" sign  
   - `good.mp4` - for the "good" sign
   - etc.

2. **File Format**: Use MP4 format for best compatibility
   - Recommended resolution: 720p or 1080p
   - Recommended frame rate: 30fps
   - Keep file sizes reasonable (under 10MB per video)

3. **File Location**: Place all video files directly in this `assets/videos/` directory

## Current Status

- The app currently uses demo videos from the internet when local videos are not available
- This allows testing the video player functionality during development
- Once you add real video files, the app will automatically use them instead of demo videos

## Example Structure

```
assets/videos/
├── happy.mp4
├── child.mp4
├── good.mp4
├── hello.mp4
├── thank_you.mp4
└── README.md (this file)
```

## Testing

The app includes fallback demo videos for development, so you can test the video player functionality even without adding real videos yet.
