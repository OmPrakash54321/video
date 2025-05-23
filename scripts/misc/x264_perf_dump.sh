#!/bin/bash

# Directory paths
INPUT_DIR="/home/root/video_sources/raw"       # Replace with the directory containing your raw YUV input videos

# Define input videos, resolutions, and presets
declare -a videos=("1280x720_15fps_1min.y4m" "1920x1080_30fps_1min.y4m")
declare -a resolutions=("1280x720" "1920x1080")
declare -a presets=("medium")
declare -a fps=("15" "30")
declare -a ch=("1" "4" "8" "16")

# Function to track memory and CPU usage
track_usage() {
    video="$1"
    preset="$2"
    mem_csv="$3"
    cpu_csv="$4"
    while true; do
        mem_usage=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        timestamp=$(date +"%H:%M:%S")
        echo "$timestamp,$mem_usage" >> "$mem_csv"
        echo "$timestamp,$cpu_usage" >> "$cpu_csv"
        sleep 1
    done
}

for ch in "${ch[@]}"; do

    echo "Ch : $ch"

    # Array to track background jobs
    jobs=()
    tracker_pids=()  # Array to store tracker PIDs

    # Trap cleanup to ensure memory and CPU tracking processes are stopped
    trap 'for pid in "${tracker_pids[@]}"; do kill $pid; wait $pid; done' EXIT

    OUTPUT_DIR="/home/root/outputx264/ch_${ch}"     # Replace with the directory where encoded outputs will be stored
    LOG_DIR="$OUTPUT_DIR/logs"                # Log files directory

    # Create output and log directories if not exist
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$LOG_DIR"

    # Iterate over videos, resolutions, and presets
    for i in "${!videos[@]}"; do
        video="${videos[$i]}"
        resolution="${resolutions[$i]}"
        fps="${fps[$i]}"
        for preset in "${presets[@]}"; do
            input_path="$INPUT_DIR/$video"

            # CSV file paths for memory and CPU usage
            mem_csv="$LOG_DIR/memory_usage_${preset}_${video%.*}.csv"
            cpu_csv="$LOG_DIR/cpu_usage_${preset}_${video%.*}.csv"

            # Clear/create CSV files with headers
            echo "Time,Memory_Usage(%)" > "$mem_csv"
            echo "Time,CPU_Usage(%)" > "$cpu_csv"

            echo "Processing: $video with preset: $preset"

            # Start memory and CPU tracking in the background
            (
                track_usage "$video" "$preset" "$mem_csv" "$cpu_csv"
            ) &
            tracker_pid=$!
            tracker_pids+=($tracker_pid)  # Store tracker PID

            # Run x265 command in parallel (background) for 4 jobs at a time
            for j in $(seq 1 $ch); do
                # Debugging: print preset and job number to check if they're being set correctly
                echo "Preset: $preset, Job: $j"

                # Update output and log path for each parallel run
                output_path="$OUTPUT_DIR/${video%.*}_${preset}_${j}.264"   # Ensure preset is included in filename
                log_path="$LOG_DIR/${video%.*}_${preset}_${j}.log"           # Ensure preset is included in log filename

                # Debugging: print paths to check if preset is included
                echo "Output Path: $output_path"
                echo "Log Path: $log_path"

                # Run x264 encoding in parallel (background)
                x264 --preset "$preset" \
                        --psnr \
                        --ssim \
                        -o "$output_path" \
                        "$input_path" > "$log_path" 2>&1 &
                
                # Log the PID of the x265 encoding process (optional)
                echo "x264 encoding PID for $video with preset $preset: $!" >> "$LOG_DIR/encoding_pids.log"
                
                # Add the background job to the jobs array
                jobs+=($!)

                # If the number of parallel jobs reaches the limit (4), wait for them to complete
                if [ "${#jobs[@]}" -ge $ch ]; then
                    # Wait for the first job to finish
                    wait ${jobs[0]}
                    # Remove the first job from the array
                    jobs=("${jobs[@]:1}")
                fi
            done

            # Check if encoding was successful
            if [ $? -eq 0 ]; then
                echo "Encoding completed: $output_path"
            else
                echo "Error processing $video with preset $preset. Check log: $log_path"
            fi
        done # End of 'presets'
    done # End of 'videos'
done # End of 'ch' loop

# Wait for all background tracker processes to finish
echo "All processes completed. Check $OUTPUT_DIR for output files, $LOG_DIR for logs, and $LOG_DIR/psnr_ssim_fps_results.csv for PSNR, SSIM, and FPS values."

