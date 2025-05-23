#!/bin/bash

# Configuration
count=8  # Number of parallel encoding processes (adjust to your CPU's core count)
Dir_PATH="/home/root/new_testing/tasksetVSparallel/slower_1080p/taskset"
video="/home/root/pedestrian_area/raw/pedestrian_area_1920x1080_30fps_yuv420p_8bit.yuv"
preset="slower"  # Encoding preset (e.g., fast, medium, slow)
input_res="1920x1080"
fps="30"
output_dir="$Dir_PATH/videos"

mkdir -p "$output_dir"

# File names for logging CPU, Memory and Time
cpu_file="$Dir_PATH/x265_8bit_CPU_${preset}_taskset.csv" #changed name to reflect taskset usage
mem_file="$Dir_PATH/x265_8bit_memory_${preset}_taskset.csv" #changed name to reflect taskset usage
log_file="$Dir_PATH/x265_8bit_log_${preset}_taskset.txt"  #changed name to reflect taskset usage
time_file="$Dir_PATH/x265_8bit_time_${preset}_taskset.csv" #changed name to reflect taskset usage

# Function to monitor CPU and Memory usage
monitor_resources() {
  while true; do
    free -m | awk 'NR==2{printf "%.2f\n", $3*100/$2 }' >> "$mem_file"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' >> "$cpu_file"
    sleep 1
  done
}

# Start monitoring CPU and memory usage in background
monitor_resources &
monitor_pid=$!

# Record start time
start_time=$(date +%s.%N)

# Loop to start parallel encoding processes
pids=()
for (( number=0; number<count; number++ ))
do
  output_file="$output_dir/out_$number.hevc"

  # Use taskset to assign each process to a specific core
  core=$number  # Assign core number based on the loop iteration
  taskset -c "$core" x265 --input "$video" --input-res "$input_res" --fps "$fps" --preset "$preset" --output "$output_file" >> "$log_file" 2>&1 &
  pids+=($!)
done

# Wait for all background processes to complete
for pid in "${pids[@]}"
do
  wait "$pid"
done

# Record end time
end_time=$(date +%s.%N)

# Calculate elapsed time
elapsed_time=$(awk "BEGIN {print $end_time - $start_time}")
echo "$elapsed_time" > "$time_file"

# Kill background monitoring processes
kill -9 "$monitor_pid"

echo "Encoding complete. Elapsed time: $elapsed_time seconds"
