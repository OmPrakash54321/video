#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    exit 1
fi

input_dir="$1"
output_dir="$2"

# Validate input directory
if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist: $input_dir"
    exit 1
fi

# Create output directory if needed
mkdir -p "$output_dir"

# Process all perf.data files
find "$input_dir" -type f -path "*/log/perf.data" | while read -r perfdata; do
    # Extract codec name from path (first directory under input_dir)
    relative_path="${perfdata#$input_dir/}"
    codec="${relative_path%%/*}"

    # Extract remaining directory components
    log_dir=$(dirname "$perfdata")
    channels_dir=$(dirname "$log_dir")
    channels=$(basename "$channels_dir")
    preset_dir=$(dirname "$channels_dir")
    preset=$(basename "$preset_dir")
    video_dir=$(dirname "$preset_dir")
    video=$(basename "$video_dir")

    # Generate output filename
    output_file="${codec}_${video}_${preset}_${channels}_perf_data_report.txt"

    # Generate perf report
    echo "Generating report: $(basename "$output_file")"
    perf report --no-children -i "$perfdata" > "$output_file"
done

echo "All perf reports generated in: $output_dir"