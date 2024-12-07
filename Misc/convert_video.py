"""
    This file converts all the .mov files to .mp4 files in the dataset folder.
"""

from glob import glob
import os
import subprocess
from tqdm import tqdm

glob_path = glob('Dataset\*\*\*.mov')

subprocess.call(['winget', "install" ,"FFmpeg (Essentials Build)"])

for i in tqdm(range(len(glob_path))):
    ip = glob_path[i]
    op = ip.replace('.MOV', '.mp4')
    
    subprocess.call(['ffmpeg', '-i', ip, op, '-loglevel', 'quiet'])

    ip = os.path.join(os.getcwd() + "\\"+ ip)

    os.remove(ip)
