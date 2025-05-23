#!/bin/bash

# # Directory paths
INPUT_DIR="/home/root/crosswalk_big"
OUTPUT_BASE="/home/root/new_testing/profile/"

# INPUT_DIR="/home/mcw/Downloads/Video/crosswalk/input_vid"
# OUTPUT_BASE="/home/mcw/Downloads/Video/crosswalk/output/"

# Configuration arrays
declare -a encoders=("x264" "x265")
# declare -a presets=("ultrafast" "veryfast" "fast" "medium" "slower")
declare -a presets=("fast" "medium")
declare -a ch_values=("4" "1")

# Get all video files from input directory
videos=()
while IFS= read -r -d $'\0' file; do
    videos+=("$(basename "$file")")
done < <(find "$INPUT_DIR" -maxdepth 1 -type f -print0)

# Function to track resource usage
track_usage() {
    local mem_csv="$1"
    local cpu_csv="$2"
    while true; do
        mem_usage=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        timestamp=$(date +"%H:%M:%S")
        echo "$timestamp,$mem_usage" >> "$mem_csv"
        echo "$timestamp,$cpu_usage" >> "$cpu_csv"
        sleep 1
    done
}

# Main encoding loop
for codec in "${encoders[@]}"; do
    for video in "${videos[@]}"; do
        video_name="${video%.*}"
        fs=$(sed -n 's/.*_\([0-9]\{1,\}x[0-9]\{1,\}\)_.*/\1/p' <<< "$video_name")
        fps=$(sed -n 's/.*_\([0-9]\{1,\}\)fps.*/\1/p' <<< "$video_name")
        echo "fs:" $fs
        echo "fps:" $fps
        for preset in "${presets[@]}"; do
            for ch in "${ch_values[@]}"; do
                # Create directory structure
                current_dir="$OUTPUT_BASE/$codec/$video_name/$preset/$ch"
                log_dir="$current_dir/log"
                mkdir -p "$log_dir"
                # Debugging: print paths to check if preset is included
                echo "Output Path: $current_dir"
                echo "Log Path: $log_dir"

                # Initialize CSV files
                mem_csv="$log_dir/memory.csv"
                cpu_csv="$log_dir/cpu.csv"
                echo "Time,Memory(%)" > "$mem_csv"
                echo "Time,CPU(%)" > "$cpu_csv"

                # Start resource monitoring
                track_usage "$mem_csv" "$cpu_csv" &
                tracker_pids+=($!)
                
                # Run parallel encoding jobs
                jobs=()
                for j in $(seq 1 $ch); do
                    # Debugging: print preset and job number to check if they're being set correctly
                    echo "codec:" $codec "video:" $video_name "preset:" $preset "ch": $ch "j:" $j
                    
                    output_file="$current_dir/${video_name}.${codec##*x}"
                    log_file="$log_dir/encode_${j}.log"
                    
                    echo "input file:" $INPUT_DIR/$video
                    echo "output file:" $output_file
                    echo "log file:" $log_file

                    # Codec-specific encoding commands
                    if [ "$codec" = "x264" ]; then
                        x264 --input-res "$fs" --fps "$fps" --preset "$preset" --psnr --ssim -o "$output_file" "$INPUT_DIR/$video" > "$log_file" 2>&1 &
                    elif [ "$codec" = "x265" ]; then
                        x265 --input-res "$fs" --fps "$fps" --input "$INPUT_DIR/$video" --preset "$preset" --psnr --ssim --output "$output_file" > "$log_file" 2>&1 &
                    fi
                    jobs+=($!)

                    # Manage parallel job queue
                    if [ "${#jobs[@]}" -ge "$ch" ]; then
                        for job in "${jobs[@]}"; do
                            wait "$job" || echo "Job $job failed"
                            jobs=("${jobs[@]:1}")
                        done
                    fi
                done

                # Cleanup
                # Trap cleanup to ensure memory and CPU tracking processes are stopped
                trap 'for pid in "${tracker_pids[@]}"; do kill $pid; wait $pid; done' EXIT SIGINT SIGTERM

                # Check if encoding was successful
                if [ $? -eq 0 ]; then
                    echo "Encoding completed: $output_path"
                else
                    echo "Error processing $video with preset $preset. Check log: $log_path"
                fi
            done
        done
    done
done

echo "All encoding processes completed successfully"

