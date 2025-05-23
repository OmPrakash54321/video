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
        fps_match = re.search(r'(\d+\.\d+) fps', last_line)
        bitrate_match = re.search(r'(\d+\.\d+) kb/s', last_line)
        
        if fps_match and bitrate_match:
            fps_values.append(float(fps_match.group(1)))
            bitrate_values.append(float(bitrate_match.group(1)))
        else:
            print("No fps and bitrate value")

    # Parse SSIM and PSNR
    for line in lines:
        if 'SSIM Mean Y:' in line:
            ssim_match = re.search(r'SSIM Mean Y: ?([0-9.]+)', line)
            if ssim_match:
                ssim = float(ssim_match.group(1))
        if 'Global PSNR:' in line:
            psnr_match = re.search(r'Global PSNR: ([0-9.]+)', line)
            if psnr_match:
                psnr_avg = float(psnr_match.group(1))
        elif 'PSNR Mean: Y:' in line:
            psnr_match = re.search(r'PSNR Mean: Y:([0-9.]+)', line)
            if psnr_match:
                psnr_avg = float(psnr_match.group(1))

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
        if 'log' in root.split(os.sep)[-1:]:
            # Extract directory components
            path_parts = root.split(os.sep)
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
    root_directory = '/home/mcw/Downloads/Video/qcs_folders/optimised_encoding/'  # Update this path if needed
    output_csv = '/home/mcw/Downloads/Video/qcs_folders/optimised_encoding/optimsed_encoder_metrics.csv'
    
    metrics_data = process_directory(root_directory)
    save_to_csv(metrics_data, output_csv)
    print(f"Report generated: {output_csv}")
