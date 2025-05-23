#!/bin/bash

# Directory paths
INPUT_DIR="/mnt/ramdisk/pedestrian_area"
OUTPUT_BASE="/mnt/ramdisk/simd_vs_nosimd_decoder_1080p"

# Configuration arrays
declare -a ch_values=("1")

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
        timestamp=$(date +"%H:%M:%S")
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        echo "$timestamp,$mem_usage" >> "$mem_csv"
        echo "$timestamp,$cpu_usage" >> "$cpu_csv"
        sleep 1
    done
}

for video in "${videos[@]}"; do
    video_name="${video%.*}"
    if [[ $video == *.265 ]]; then
        codec="h265"
    elif [[ $video == *.264 ]]; then
        codec="h264"
    fi
    for ch in "${ch_values[@]}"; do
        # Create directory structure
        current_dir="$OUTPUT_BASE/$codec/$video_name/$ch"_ch""
        log_dir="$current_dir/log"
        mkdir -p "$log_dir"

        # Initialize CSV files
        mem_csv="$log_dir/memory.csv"
        cpu_csv="$log_dir/cpu.csv"
        echo "Time,Memory(%)" > "$mem_csv"
        echo "Time,CPU(%)" > "$cpu_csv"

        # Start resource monitoring
        track_usage "$mem_csv" "$cpu_csv" &
        tracker_pid=$!

        # Stop resource monitoring
        trap 'kill $tracker_pid 2>/dev/null; wait $tracker_pid 2>/dev/null || true; exit' EXIT SIGINT SIGTERM

        # Run parallel encoding jobs
        jobs=()
        for j in $(seq 1 $ch); do
            # Build encoder command
            output_file="./out.yuv" # Override the files
            echo "Processing $output_file"
            log_file="$log_dir/encode_${j}.log"
            
            # perf record -o "$log_dir/perf_$j.data" -F 99 -g -e cpu-cycles,instructions,cycles,cache-misses,branch-misses,context-switches,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses -- ffmpeg -i "$INPUT_DIR/$video" -f rawvideo -pix_fmt yuv420p "$output_file" > "$log_file" 2>&1 &
            ffmpeg_no_strip -i "$INPUT_DIR/$video" -f rawvideo -pix_fmt yuv420p "$output_file" > "$log_file" 2>&1 &
            jobs+=($!)
        done

        # Wait for jobs and cleanup
        while [ ${#jobs[@]} -gt 0 ]; do
            wait "${jobs[0]}" || echo "Job ${jobs[0]} failed"
            jobs=("${jobs[@]:1}")
        done

        # Kill the tracking
        kill $tracker_pid
        # Wait for the tracking process to terminate
        wait "$tracker_pid" || true

        sleep 5
    done
done

echo "All encoding processes completed successfully"
