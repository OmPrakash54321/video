# <!-- Task overview.
# create a python script which analyses the files below and dumps fps, ssim, psnr, bitrate, cpu usage values
# in a single csv file. 
# The files below containes the terminal log for x264 encoder.

# x264
# 	|-> video0
# 		|->fast
# 			|-> 1
# 				|->log
# 					|->cpu.csv
# 					|->encode1.log
# 					|->memory.csv
# 			|-> 4
# 				|->log
# 					|->cpu.csv
# 					|->encode1.log
# 					|->encode2.log
# 					|->encode3.log
# 					|->encode4.log
# 					|->memory.csv
# 			|-> 8
# 				|->log
# 					|->...
# 			|-> 16
# 				|->log
# 					|->...
# 		|-> medium
# 		|-> ...
# 	|-> video1
# 	|-> ...
# The above is the directory structure. Here u can see, inside x264 dir, there are many videos.
# Insider a single video, there are many preset folders like fast, medium, slow..
# Inside each preset folder, there are channels directory like 1, 4, 8 and 16.
# Inside each channel, there is a log dir.
# Insider log, there would be memory.csv, cpu.csv, encode.log
# The encode.log file number would be equal to the corresponding channel directory.
# Eg. if ch dir is 1, there will be 1 encode.log. If the channel dir is 4, there will be 4 encode.txt files with names encode_1.log...until encode_4.log.
# this is same for 8 and 16 channels as well.


# Below is a single example of a log file of a 1ch encoder.

# yuv [info]: 640x360p 0:0 @ 30/1 fps (cfr)
# x264 [warning]: --psnr used with psy on: results will be invalid!
# x264 [warning]: --tune psnr should be used if attempting to benchmark psnr!
# x264 [info]: using cpu capabilities: ARMv8 NEON
# x264 [info]: profile High 10, level 3.0, 4:2:0, 10-bit
# [0.7%] 1/150 frames, 4.82 fps, 35085.36 kb/s, eta 0:00:30  
# [10.0%] 15/150 frames, 32.78 fps, 33609.71 kb/s, eta 0:00:04  
# [19.3%] 29/150 frames, 40.58 fps, 33503.05 kb/s, eta 0:00:02  
# [26.7%] 40/150 frames, 40.63 fps, 33492.92 kb/s, eta 0:00:02  
# [30.0%] 45/150 frames, 36.22 fps, 33503.61 kb/s, eta 0:00:02  
# [38.7%] 58/150 frames, 38.37 fps, 33513.26 kb/s, eta 0:00:02  
# [48.0%] 72/150 frames, 40.67 fps, 33484.03 kb/s, eta 0:00:01  
# [57.3%] 86/150 frames, 42.43 fps, 33494.88 kb/s, eta 0:00:01  
# [63.3%] 95/150 frames, 40.97 fps, 33467.42 kb/s, eta 0:00:01  
# [68.7%] 103/150 frames, 39.79 fps, 33467.65 kb/s, eta 0:00:01  
# [78.0%] 117/150 frames, 40.98 fps, 33458.35 kb/s, eta 0:00:00  
# [87.3%] 131/150 frames, 42.16 fps, 33443.68 kb/s, eta 0:00:00  
# [98.0%] 147/150 frames, 43.61 fps, 33427.90 kb/s, eta 0:00:00  
                                                                               
# x264 [info]: frame I:1     Avg QP:47.43  size:146189  PSNR Mean Y:27.25 U:31.03 V:31.04 Avg:28.19 Global:28.19
# x264 [info]: frame P:140   Avg QP:47.78  size:139205  PSNR Mean Y:26.91 U:30.76 V:30.70 Avg:27.85 Global:27.84
# x264 [info]: frame B:9     Avg QP:47.92  size:139276  PSNR Mean Y:26.63 U:30.56 V:30.42 Avg:27.58 Global:27.58
# x264 [info]: consecutive B-frames: 92.0%  0.0%  0.0%  8.0%
# x264 [info]: mb I  I16..4:  0.0%  0.0% 100.0%
# x264 [info]: mb P  I16..4: 95.6%  0.5%  3.9%  P16..4:  0.0%  0.0%  0.0%  0.0%  0.0%    skip: 0.0%
# x264 [info]: mb B  I16..4: 12.8% 17.0% 14.8%  B16..8:  3.0% 15.9% 32.1%  direct: 4.3%  skip: 0.0%  L0: 9.0% L1: 7.2% BI:83.9%
# x264 [info]: 8x8 transform intra:1.5% inter:7.0%
# x264 [info]: coded y,uvDC,uvAC intra: 99.5% 100.0% 100.0% inter: 100.0% 100.0% 100.0%
# x264 [info]: i16 v,h,dc,p:  0%  0% 93%  7%
# x264 [info]: i8 v,h,dc,ddl,ddr,vr,hd,vl,hu:  6%  4% 61%  4%  6%  4%  5%  4%  5%
# x264 [info]: i4 v,h,dc,ddl,ddr,vr,hd,vl,hu: 32%  4% 25%  7%  7%  6%  7%  6%  6%
# x264 [info]: i8c dc,h,v,p: 91%  0%  1%  8%
# x264 [info]: Weighted P-Frames: Y:0.0% UV:0.0%
# x264 [info]: ref P L0: 80.0% 20.0%
# x264 [info]: ref B L0: 84.4% 15.6%
# x264 [info]: ref B L1: 91.8%  8.2%
# x264 [info]: SSIM Mean Y:0.9862438 (18.615db)
# x264 [info]: PSNR Mean Y:26.893 U:30.748 V:30.682 Avg:27.834 Global:27.829 kb/s:33421.35

# encoded 150 frames, 43.86 fps, 33421.36 kb/s


# How to calculate ?
# 1. fps
# in the last line of the log, u can see fps. 
# In case of multiple channesl like 4, 8, 16. u shoudl calculate the average of all the encode file fps.
# 2. bitrate
# it is in the last line of the log.
# Similarly u can take the average of the bitrate
# 3. ssim
# U can find it in SSIM Mean Y
# dump it
# 4. psnr.
# U can find it in PSNR Mean Y
# Use the Avg value in that line.
# 5. cpu usage.
# It is present in the cpu.csv file
# Read the file. Average of all the cpu usage values in the file. -->


import os
import csv
import re
import pandas as pd
from collections import defaultdict

def parse_encode_log(log_path):
    fps_values = []
    bitrate_values = []
    ssim = None
    psnr_avg = None

    with open(log_path, 'r') as f:
        lines = f.readlines()

    # Parse FPS and Bitrate from last line
    last_line = lines[-1].strip()
    if last_line.startswith('encoded'):
        match = re.search(r'(\d+\.\d+) fps, (\d+\.\d+) kb/s', last_line)
        if match:
            fps_values.append(float(match.group(1)))
            bitrate_values.append(float(match.group(2)))

    # Parse SSIM and PSNR
    for line in lines:
        if 'SSIM Mean Y:' in line:
            ssim = float(re.search(r'SSIM Mean Y: ?([0-9.]+)', line).group(1))
        if 'PSNR Mean Y:' in line and 'Avg:' in line:
            psnr_avg = float(re.search(r'Avg:([0-9.]+)', line).group(1))

    return fps_values, bitrate_values, ssim, psnr_avg

def parse_cpu_csv(csv_path):
    try:
        df = pd.read_csv(csv_path)
        if 'cpu_usage' in df.columns:
            return df['cpu_usage'].mean()
        return None
    except Exception as e:
        print(f"Error reading {csv_path}: {str(e)}")
        return None

def extract_resolution(video_name):
    """Extracts resolution (width, height) from video name."""
    match = re.search(r'_(\d+)x(\d+)_', video_name)
    if match:
        width = int(match.group(1))
        height = int(match.group(2))
        return width, height
    return None, None

def process_directory(root_dir):
    results = defaultdict(lambda: defaultdict(list))
    
    for root, dirs, files in os.walk(root_dir):
        print(f'root {root}')
        print(f'dirs {dirs}')
        print(f'files {files}')
        if 'log' in root.split(os.sep)[-1:]:
            # Extract directory components
            path_parts = root.split(os.sep)
            print("path_parts", path_parts)
            try:
                if 'x264' in path_parts:
                    video_idx = path_parts.index('x264') + 1
                elif 'x265' in path_parts:
                    video_idx = path_parts.index('x265') + 1
                video = path_parts[video_idx]
                preset = path_parts[video_idx + 1]
                channels = path_parts[video_idx + 2]
            except IndexError:
                continue

            # Collect all encode logs
            encode_logs = [f for f in files if f.startswith('encode') and f.endswith('.log')]
            if not encode_logs:
                continue

            # Process encode logs
            total_fps = []
            total_bitrate = []
            ssim_values = []
            psnr_values = []

            for log_file in encode_logs:
                fps, bitrate, ssim, psnr = parse_encode_log(os.path.join(root, log_file))
                total_fps.extend(fps)
                total_bitrate.extend(bitrate)
                if ssim is not None:
                    ssim_values.append(ssim)
                if psnr is not None:
                    psnr_values.append(psnr)

            # Calculate averages
            avg_fps = sum(total_fps) / len(total_fps) if total_fps else None
            avg_bitrate = sum(total_bitrate) / len(total_bitrate) if total_bitrate else None
            avg_ssim = sum(ssim_values) / len(ssim_values) if ssim_values else None
            avg_psnr = sum(psnr_values) / len(psnr_values) if psnr_values else None

            # Process CPU CSV
            cpu_avg = parse_cpu_csv(os.path.join(root, 'cpu.csv'))

            results[video][preset].append({
                'Channels': int(channels),  # Convert channels to integer for proper sorting
                'FPS': avg_fps,
                'Bitrate': avg_bitrate,
                'SSIM': avg_ssim,
                'PSNR': avg_psnr,
                'CPU Usage': cpu_avg
            })

    return results

def save_to_csv(data, output_file):
    if not data:
        print("No data to save")
        return

    presets_order = ['ultrafast', 'veryfast', 'fast', 'medium', 'slow', 'slower']

    # Sort videos by resolution
    def video_sort_key(video_name):
        width, height = extract_resolution(video_name)
        return (width or 0, height or 0)  # Sort by width, then height, default to 0 if no resolution found

    sorted_videos = sorted(data.keys(), key=video_sort_key)
    
    with open(output_file, 'w', newline='') as f:
        fieldnames = ['Video', 'Preset', 'Channels', 'FPS', 'Bitrate', 'SSIM', 'PSNR', 'CPU Usage']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        # Write header row in bold (using a simple text-based approach)
        header = {field: f'{field}' for field in fieldnames}
        writer.writerow(header)

        for video in sorted_videos:
            video_name_written = False  # Flag to track if video name has been written

            for preset in presets_order:
                if preset in data[video]:
                    preset_name_written = False  # Flag to track if preset name has been written
                    
                    # Sort channels in ascending order
                    channels_data = sorted(data[video][preset], key=lambda x: x['Channels'])
                    for row in channels_data:
                        row_to_write = {
                            'Video': video if not video_name_written else '',
                            'Preset': preset if not preset_name_written else '',
                            'Channels': row['Channels'],
                            'FPS': row['FPS'],
                            'Bitrate': row['Bitrate'],
                            'SSIM': row['SSIM'],
                            'PSNR': row['PSNR'],
                            'CPU Usage': row['CPU Usage']
                        }
                        writer.writerow(row_to_write)
                        video_name_written = True
                        preset_name_written = True
            writer.writerow({})  # Add an empty row after each video

if __name__ == '__main__':
    root_directory = '/home/mcw/Downloads/Video/crosswalk/output/'  # Update this path if needed
    output_csv = '/home/mcw/Downloads/Video/crosswalk/output/encoder_metrics.csv'
    
    metrics_data = process_directory(root_directory)
    save_to_csv(metrics_data, output_csv)
    print(f"Report generated: {output_csv}")
