from glob import glob
import os
import subprocess
from tqdm import tqdm

glob_path = glob('Dataset\*\*\*.mov')

for i in tqdm(range(len(glob_path))):
    ip = glob_path[i]
    op = ip.replace('.MOV', '.mp4')
    subprocess.call(['ffmpeg', '-i', ip, op, '-loglevel', 'quiet'])

    ip = os.path.join(os.getcwd() + "\\"+ ip)

    os.remove(ip)
# test_ip = glob_path[1]
# test_op = test_ip.replace('.MOV', '.mp4')

# print(test_ip)
# print(test_op)

# subprocess.call(['ffmpeg', '-i', test_ip, test_op])

# test_ip = os.path.join(os.getcwd() + "\\"+ test_ip)

# os.remove(test_ip)
