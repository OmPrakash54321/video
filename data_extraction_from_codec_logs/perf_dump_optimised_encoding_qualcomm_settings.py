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
        elif 'PSNR Mean Y:' in line and 'Avg:' in line:
            psnr_match = re.search(r'Avg:([0-9.]+)', line)
            if psnr_match:
                psnr_avg = float(psnr_match.group(1))

    return fps_values, bitrate_values, ssim, psnr_avg

def parse_cpu_csv(csv_path):
    try:
        df = pd.read_csv(csv_path)
        return df['cpu_usage'].mean() if 'cpu_usage' in df.columns else None
    except Exception as e:
        print(f"Error reading {csv_path}: {str(e)}")
        return None

def extract_param_value(dir_name):
    """Extracts the numerical value from directory names with suffixes"""
    return dir_name.split('_')[0]

def get_sort_key(combo):
    """Custom sorting key for (GOP, bframes) combinations"""
    gop, bf = combo
    try:
        gop_val = int(gop)
    except ValueError:
        gop_val = 0
    
    try:
        bf_val = int(bf)
    except ValueError:
        # Handle 'null' as lowest priority
        bf_val = -1 if bf == 'null' else 0
    
    return (gop_val, bf_val)

def process_directory(root_dir):
    results = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))

    for root, dirs, files in os.walk(root_dir):
        encode_logs = [f for f in files if f.startswith('encode') and f.endswith('.log')]
        if not encode_logs:
            continue

        try:
            path_parts = root.split(os.sep)
            if 'x264' in path_parts:
                base_idx = path_parts.index('x264')
            elif 'x265' in path_parts:
                base_idx = path_parts.index('x265')
            else:
                continue

            # Extract parameters with new directory name handling
            video = path_parts[base_idx + 1]
            preset = path_parts[base_idx + 2]
            channels = extract_param_value(path_parts[base_idx + 3])  # 1_ch -> 1
            gop = extract_param_value(path_parts[base_idx + 4])       # 149_GOP -> 149
            bframes = extract_param_value(path_parts[base_idx + 5])   # 0_bframes -> 0
        except IndexError:
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
        cpu_avg = parse_cpu_csv(os.path.join(root, 'cpu.csv'))

        # Store metrics with GOP/bframes combination as key
        results[video][preset][channels][(gop, bframes)] = {
            'FPS': avg_fps,
            'Bitrate': avg_bitrate,
            'SSIM': avg_ssim,
            'PSNR': avg_psnr,
            'CPU Usage': cpu_avg
        }

    return results

def save_to_csv(data, output_file):
    if not data:
        print("No data to save")
        return

    # Collect all unique GOP/bframes combinations
    unique_combos = set()
    for video_data in data.values():
        for preset_data in video_data.values():
            for channels_data in preset_data.values():
                unique_combos.update(channels_data.keys())

    # Sort combinations using custom key
    sorted_combos = sorted(unique_combos, key=get_sort_key)

    # Create headers
    presets_order = ['ultrafast', 'veryfast', 'fast', 'medium', 'slow', 'slower']
    fieldnames = ['Video', 'Preset', 'Channels']
    
    # Create column headers for each combination
    for gop, bf in sorted_combos:
        fieldnames.extend([
            f'FPS ({gop},{bf})',
            f'Bitrate ({gop},{bf})',
            f'SSIM ({gop},{bf})',
            f'PSNR ({gop},{bf})'
        ])
        fieldnames.append('')  # Add empty column between groups

    # Remove trailing empty column
    if fieldnames and fieldnames[-1] == '':
        fieldnames.pop()

    # Write CSV
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(fieldnames)

        # Sort videos by resolution
        def video_sort_key(video_name):
            match = re.search(r'_(\d+)x(\d+)_', video_name)
            if match:
                return (int(match.group(1)), int(match.group(2)))
            return (0, 0)

        for video in sorted(data.keys(), key=video_sort_key):
            video_written = False
            
            for preset in presets_order:
                if preset not in data[video]:
                    continue
                
                # Sort channels numerically
                channels_data = data[video][preset]
                for channels in sorted(channels_data.keys(), key=lambda x: int(x)):
                    row = [video if not video_written else '', preset, channels]
                    video_written = True
                    
                    # Add metrics for each combination
                    for combo in sorted_combos:
                        metrics = channels_data[channels].get(combo, {})
                        row.extend([
                            metrics.get('FPS', ''),
                            metrics.get('Bitrate', ''),
                            metrics.get('SSIM', ''),
                            metrics.get('PSNR', '')
                        ])
                        # Add empty column between groups
                        if combo != sorted_combos[-1]:
                            row.append('')
                    
                    writer.writerow(row)
            
            # Add empty row between videos
            writer.writerow([])

if __name__ == '__main__':
    root_directory = '/home/mcw/Downloads/MCW/Video/qcs_folders/load_vs_noload/taskset/1080p_8_cores/x265'
    output_csv = '/home/mcw/Downloads/MCW/Video/qcs_folders/load_vs_noload/taskset/1080p_8_cores/x265/x265_fps.csv'
    
    metrics_data = process_directory(root_directory)
    save_to_csv(metrics_data, output_csv)
    print(f"Report generated: {output_csv}")
