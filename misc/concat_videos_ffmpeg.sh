#!/bin/bash

# Directory containing list.txt files
list_dir="/home/gfr/qualcomm/videos_concat/concatenated_vids"

# Iterate over all list.txt files in the directory
for list_file in "$list_dir"/*.txt; do
  # Extract the first line from the list.txt file
  first_line=$(head -n 1 "$list_file")
  
  # Extract the video filename from the first line (removing "file '")
  video_name=$(echo "$first_line" | sed -r "s/file '(.+)'/\1/")
  
  # Extract just the base name of the video file (e.g., x264_fast_default_pedestrian_area_1920x1080_30fps_yuv420p_8bit.264)
  output_video=$(basename "$video_name")
  
  # Execute the FFmpeg command
  ffmpeg -f concat -safe 0 -i "$list_file" -c copy "$output_video"
  
  echo "Processed $list_file -> $output_video"
done
