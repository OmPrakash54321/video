#!/bin/bash

# Input directory containing videos
input_dir="/home/gfr/qualcomm/videos_concat/"

# Output directory for list.txt files
output_dir="/home/gfr/qualcomm/videos_concat/concatenated_vids/"
mkdir -p "$output_dir"  # Create output directory if it doesn't exist

# Iterate over all video files in the input directory
for video in "$input_dir"/*; do
  # Extract the base name of the video file (e.g., video.264)
  base_name=$(basename "$video")
  
  # Create a list.txt file for this video
  output_file="$output_dir/${base_name}_list.txt"
  
  # Write the path of the video 10 times into the list.txt file
  for i in {1..10}; do
    echo "file '$video'" >> "$output_file"
  done
  
  echo "Created $output_file"
done
