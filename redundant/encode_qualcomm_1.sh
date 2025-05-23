#!/bin/bash

# Directory paths
INPUT_DIR="/home/root/crosswalk_big"
OUTPUT_BASE="/home/root/new_testing/profile/"

# Configuration arrays
declare -a encoders=("x264" "x265")
declare -a presets=("ultrafast" "veryfast" "fast" "medium" "slower")
declare -a ch_values=("1" "4")
declare -a keyint_values=(149 150)
declare -a bframes_values=("null" "0" "1")

# Constant values
bitrate=4200
qpmin=22
qpmax=40

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
        for preset in "${presets[@]}"; do
            for ch in "${ch_values[@]}"; do
                for keyint in "${keyint_values[@]}"; do
                    for bframes in "${bframes_values[@]}"; do
                        # Create directory structure
                        current_dir="$OUTPUT_BASE/$codec/$video_name/$preset/$ch/$keyint/$bframes"
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

                        # Run parallel encoding jobs
                        jobs=()
                        for j in $(seq 1 $ch); do
                            # Build bframes argument
                            bframes_option=""
                            if [ "$bframes" != "null" ]; then
                                bframes_option="--bframes $bframes"
                                if [ "$codec" = "x265" ]; then
                                    bframes_option="--bframes $bframes"
                                fi
                            fi

                            # Build encoder command
                            output_file="$current_dir/${video_name}.${codec##*x}"
                            log_file="$log_dir/encode_${j}.log"
                            
                            if [ "$codec" = "x264" ]; then
                                x264 --input-res "$fs" --fps "$fps" --preset "$preset" \
                                    --bitrate $bitrate --qpmin $qpmin --qpmax $qpmax \
                                    --keyint $keyint $bframes_option --psnr --ssim \
                                    -o "$output_file" "$INPUT_DIR/$video" > "$log_file" 2>&1 &
                            elif [ "$codec" = "x265" ]; then
                                x265 --input-res "$fs" --fps "$fps" --input "$INPUT_DIR/$video" \
                                    --preset "$preset" --bitrate $bitrate --qpmin $qpmin \
                                    --qpmax $qpmax --key-int $keyint $bframes_option --psnr --ssim \
                                    --output "$output_file" > "$log_file" 2>&1 &
                            fi
                            jobs+=($!)
                        done

                        # Wait for jobs and cleanup
                        for job in "${jobs[@]}"; do
                            wait "$job" || echo "Job $job failed"
                        done
                        
                        # Stop resource monitoring
                        kill $tracker_pid
                        wait $tracker_pid 2>/dev/null

                        # Check encoding success
                        if [ $? -eq 0 ]; then
                            echo "Encoding completed: $current_dir"
                        else
                            echo "Error processing $video with preset $preset. Check log: $log_dir"
                        fi
                    done
                done
            done
        done
    done
done

echo "All encoding processes completed successfully"
