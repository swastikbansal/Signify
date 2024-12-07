from flask import Flask, request, jsonify
import requests
import os
from urllib.parse import urlparse
from werkzeug.utils import secure_filename

app = Flask(__name__)

def process_video(video_path):
    
    pass

@app.route('/download', methods=['GET','POST'])
def download_video():
    data = request.get_json()
    
    if not data or 'link' not in data:
        return jsonify({'error': 'No link provided'}), 400
    
    link = data['link']
    print(link)
    
    try:
        # Get the video content
        response = requests.get(link, stream=True)
        response.raise_for_status()
        
        # Extract the video filename from the link
        parsed_url = urlparse(link)
        filename = os.path.basename(parsed_url.path)
        filename = secure_filename(filename)
        
        # Save the video locally
        with open(filename, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return jsonify({'message': f'Video downloaded successfully as {filename}'}), 200
    
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)