#!/bin/bash

# Directory paths
INPUT_DIR="/home/root/main_video/combin_8bit_new/264/null_bframes"
OUTPUT_BASE="/home/root/decoder/max_channels_achieved/2160/"

declare -a ch_values=("32")

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

for video in "${videos[@]}"; do
    video_name="${video%.*}"
    fs=$(sed -n 's/.*_\([0-9]\{1,\}x[0-9]\{1,\}\)_.*/\1/p' <<< "$video_name")
    fps=$(sed -n 's/.*_\([0-9]\{1,\}\)fps.*/\1/p' <<< "$video_name")
    for ch in "${ch_values[@]}"; do
	# Create directory structure
	current_dir="$OUTPUT_BASE/$video_name/$ch"_ch""
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
	# trap 'kill $tracker_pid; wait $tracker_pid' EXIT SIGINT SIGTERM
	trap 'kill $tracker_pid 2>/dev/null; wait $tracker_pid 2>/dev/null || true; exit' EXIT SIGINT SIGTERM

	# Run parallel encoding jobs
	jobs=()
	for j in $(seq 1 $ch); do
	    # Build encoder command
	    output_file="/home/root/out.yuv"
	    echo "Processing $output_file"
	    log_file="$log_dir/encode_${j}.log"
	    
	    ffmpeg -i "$INPUT_DIR/$video" -f rawvideo -pix_fmt yuv420p "$output_file" > "$log_file" 2>&1 &
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

	# Check encoding success
	if ! kill -0 "$tracker_pid" 2>/dev/null && [ ${#jobs[@]} -eq 0 ]; then
	    echo "Encoding completed"
	else
	    if kill -0 "$tracker_pid" 2>/dev/null; then
		echo "Error: Tracker still running"
	    elif ! [ ${#jobs[@]} -eq 0 ]; then
		echo "Error: Jobs not complete yet. Pending jobs: ${#jobs[@]}, Job ${job[0]}"
	    else
		echo "Error: Something else"
	    fi
	fi
    done
done


echo "All encoding processes completed successfully"
