#!/bin/bash

echo "Am I working"

# Directory paths
INPUT_DIR_x264="/home/root/decode_source/264"
INPUT_DIR_x265="/home/root/decode_source/265"
OUTPUT_BASE="/home/root/new_testing/output_decode/"

# Configuration arrays
declare -a encoders=("x264" "x265")
declare -a ch_values=("1" "4")

# Get all video files from input directories
videos264=()
while IFS= read -r -d $'\0' file; do
    videos264+=("$(basename "$file")")
done < <(find "$INPUT_DIR_x264" -maxdepth 1 -type f -print0)

videos265=()
while IFS= read -r -d $'\0' file; do
    videos265+=("$(basename "$file")")
done < <(find "$INPUT_DIR_x265" -maxdepth 1 -type f -print0)

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
    if [ "$codec" = "x264" ]; then
        videos=("${videos264[@]}")
        INPUT_DIR="$INPUT_DIR_x264"
    elif [ "$codec" = "x265" ]; then
        videos=("${videos265[@]}")
        INPUT_DIR="$INPUT_DIR_x265"
    fi

    for video in "${videos[@]}"; do
        video_name="${video%.*}"
        for ch in "${ch_values[@]}"; do
            # Create directory structure
            current_dir="$OUTPUT_BASE/$codec/$video_name/$ch"
            log_dir="$current_dir/log"
            mkdir -p "$log_dir"
            echo "Output Path: $current_dir"
            echo "Log Path: $log_dir"

            # Initialize CSV files
            mem_csv="$log_dir/memory.csv"
            cpu_csv="$log_dir/cpu.csv"
            echo "Time,Memory(%)" > "$mem_csv"
            echo "Time,CPU(%)" > "$cpu_csv"

            # Start resource monitoring
            track_usage "$mem_csv" "$cpu_csv" &
            tracker_pid=$!

            # Run parallel encoding jobs
            jobs=()
            for j in $(seq 1 $ch); do
                echo "codec: $codec, video: $video_name, ch: $ch, j: $j"
                output_file="/home/root/out_vids_decode/${video_name}.yuv"
                log_file="$log_dir/encode_${j}.log"

                ffmpeg -i "$INPUT_DIR/$video" -f rawvideo -pix_fmt yuv420p "$output_file" > "$log_file" 2>&1 &
                jobs+=($!)

                # Manage parallel job queue
                if [ "${#jobs[@]}" -ge "$ch" ]; then
                    for job in "${jobs[@]}"; do
                        wait "$job" || echo "Job $job failed"
                        jobs=("${jobs[@]:1}")
                    done
                fi
            done

            trap 'for pid in "${tracker_pids[@]}"; do kill $pid; wait $pid; done' EXIT SIGINT SIGTERM

            # Check if encoding was successful
            if [ $? -eq 0 ]; then
                echo "Encoding completed: $current_dir"
            else
                echo "Error processing $video. Check log: $log_dir"
            fi
        done
    done
done

echo "All encoding processes completed successfully"