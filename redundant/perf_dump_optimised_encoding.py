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

    last_line = lines[-1].strip()
    if last_line.startswith('encoded'):
        fps_match = re.search(r'(\d+\.\d+) fps', last_line)
        bitrate_match = re.search(r'(\d+\.\d+) kb/s', last_line)
        
        if fps_match and bitrate_match:
            fps_values.append(float(fps_match.group(1)))
            bitrate_values.append(float(bitrate_match.group(1)))

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
        return df['cpu_usage'].mean() if 'cpu_usage' in df.columns else None
    except Exception as e:
        print(f"Error reading {csv_path}: {str(e)}")
        return None

def extract_number(s):
    match = re.search(r'\d+', s)
    return int(match.group()) if match else 0

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

            video = path_parts[base_idx + 1]
            preset = path_parts[base_idx + 2]
            channels = path_parts[base_idx + 3]
            gop = path_parts[base_idx + 4]
            bframes = path_parts[base_idx + 5]
        except IndexError:
            continue

        total_fps = []
        total_bitrate = []
        ssim_values = []
        psnr_values = []

        for log_file in encode_logs:
            fps, bitrate, ssim, psnr = parse_encode_log(os.path.join(root, log_file))
            total_fps.extend(fps)
            total_bitrate.extend(bitrate)
            if ssim is not None: ssim_values.append(ssim)
            if psnr is not None: psnr_values.append(psnr)

        avg_fps = sum(total_fps)/len(total_fps) if total_fps else None
        avg_bitrate = sum(total_bitrate)/len(total_bitrate) if total_bitrate else None
        avg_ssim = sum(ssim_values)/len(ssim_values) if ssim_values else None
        avg_psnr = sum(psnr_values)/len(psnr_values) if psnr_values else None
        cpu_avg = parse_cpu_csv(os.path.join(root, 'cpu.csv'))

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

    # Sort combinations by GOP then bframes
    sorted_combos = sorted(unique_combos, 
                         key=lambda x: (extract_number(x[0]), extract_number(x[1])))

    # Create headers
    presets_order = ['ultrafast', 'veryfast', 'fast', 'medium', 'slow', 'slower']
    fieldnames = ['Video', 'Preset', 'Channels']
    
    for i, (gop, bf) in enumerate(sorted_combos):
        fieldnames.extend([
            f'FPS ({gop},{bf})',
            f'Bitrate ({gop},{bf})',
            f'SSIM ({gop},{bf})',
            f'PSNR ({gop},{bf})'
        ])
        if i != len(sorted_combos)-1:
            fieldnames.append('')

    # Write CSV
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(fieldnames)

        # Sort videos by resolution
        def video_sort_key(video_name):
            match = re.search(r'_(\d+)x(\d+)_', video_name)
            return (int(match.group(1)), int(match.group(2))) if match else (0, 0)

        for video in sorted(data.keys(), key=video_sort_key):
            video_written = False
            
            for preset in presets_order:
                if preset not in data[video]:
                    continue
                
                # Sort channels numerically
                channels_data = data[video][preset]
                for channels in sorted(channels_data.keys(), key=lambda x: int(x)):
                    row = [video, preset, channels]
                    
                    for i, combo in enumerate(sorted_combos):
                        metrics = channels_data[channels].get(combo, {})
                        row.extend([
                            metrics.get('FPS', ''),
                            metrics.get('Bitrate', ''),
                            metrics.get('SSIM', ''),
                            metrics.get('PSNR', '')
                        ])
                        if i != len(sorted_combos)-1:
                            row.append('')
                    
                    writer.writerow(row)
                    video_written = True
            
            if video_written:
                writer.writerow([])

if __name__ == '__main__':
    root_directory = '/home/mcw/Downloads/Video/qcs_folders/optimised_encoding/x264/'
    output_csv = '/home/mcw/Downloads/Video/qcs_folders/optimised_encoding/x264_optimised_encoder_metrics.csv'
    
    metrics_data = process_directory(root_directory)
    save_to_csv(metrics_data, output_csv)
    print(f"Report generated: {output_csv}")
