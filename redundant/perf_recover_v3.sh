#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    exit 1
fi

input_dir="$1"
output_dir="$2"

if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory does not exist: $input_dir"
    exit 1
fi

mkdir -p "$output_dir"

find "$input_dir" -type f -path "*/log/perf*.data" | while read -r perfdata; do
    filename=$(basename "$perfdata")
    base_prefix="${filename%.data}"
    suffix="${base_prefix#perf}"
    number="${suffix#_}"
    
    if [ -n "$number" ]; then
        perf_suffix="_${number}"
    else
        perf_suffix=""
    fi

    relative_path="${perfdata#$input_dir/}"
    codec="${relative_path%%/*}"

    # Extract directory components from new structure
    log_dir=$(dirname "$perfdata")
    bframes_dir=$(dirname "$log_dir")
    gop_dir=$(dirname "$bframes_dir")
    channels_dir=$(dirname "$gop_dir")
    preset_dir=$(dirname "$channels_dir")
    video_dir=$(dirname "$preset_dir")

    # Get directory names
    gop=$(basename "$gop_dir")
    bframes=$(basename "$bframes_dir")
    channels=$(basename "$channels_dir")
    preset=$(basename "$preset_dir")
    video=$(basename "$video_dir")

    # Create output filename with new components
    output_file="$output_dir/${codec}_${video}_${preset}_${channels}_${gop}_${bframes}_perf${perf_suffix}_data_report.txt"

    echo "Generating report: $(basename "$output_file")"
    perf report --no-children --stdio --stdio-color never -i "$perfdata" > "$output_file"
    sleep 3
done

echo "All perf reports generated in: $output_dir"
