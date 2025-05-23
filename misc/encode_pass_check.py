import os
from pathlib import Path

def check_encodes(root_dir):
    failed_logs = []
    total_logs = 0

    for path in Path(root_dir).rglob('log'):
        if path.is_dir():
            for log_file in path.glob('encode_*.log'):
                total_logs += 1
                last_line = ''
                
                try:
                    with open(log_file, 'r') as f:
                        lines = f.readlines()
                        if lines:
                            last_line = lines[-1].strip()
                except Exception as e:
                    failed_logs.append(str(log_file))
                    continue

                if 'encoded' not in last_line:
                    failed_logs.append(str(log_file))

    if not failed_logs and total_logs > 0:
        print("All encodes done!")
    elif total_logs == 0:
        print("No encode logs found in directory structure")
    else:
        print(f"Failed encodes ({len(failed_logs)}/{total_logs}):")
        for log in failed_logs:
            print(f"Failed: {log}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", help="Root directory to check encodes")
    args = parser.parse_args()
    
    check_encodes(args.directory)
