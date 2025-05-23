#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -f <source_frame_size> -r <source_frame_rate> -s <source_video> -d <destination_directory> -n <output file name> -b <bit_depth>"
    exit 1
}

# Parse command line arguments
while getopts ":s:d:f:r:n:b:" opt; do
    case ${opt} in
        s )
            source_video=$OPTARG
            ;;
        d )
            destination_directory=$OPTARG
            ;;
	f )
	    input_frame_size=$OPTARG
	    ;;
	r )
	   input_frame_rate=$OPTARG
	   ;;
	n )
	   out_file_name=$OPTARG
	   ;;
	b )
	   bit_depth=$OPTARG
	   ;;
        \? )
            usage
            ;;
    esac
done

# Check if both source and destination are provided
if [ -z "$source_video" ] || [ -z "$destination_directory" ] || [ -z "$input_frame_size" ] || [ -z "$input_frame_rate" ]|| [ -z "$out_file_name" ] || [ -z "$bit_depth" ]; then
	usage
fi

echo "source_video: $source_video"
echo "destination_directory: $destination_directory"
echo "input_frame_size: $input_frame_size"
echo "input_frame_rate: $input_frame_rate"
echo "out_file_name: $out_file_name"
echo "bit_depth: $bit_depth"

# Create destination directory if it doesn't exist
mkdir -p "$destination_directory"

# Declare associative arrays
declare -A r1 r2 r3 r4 r5 r6

# Assign values to associative arrays
r1=([res_x]="640"  [res_y]="360"  [fps]="30")
r2=([res_x]="1920" [res_y]="1080" [fps]="30")
r3=([res_x]="2560" [res_y]="1920" [fps]="15")
r4=([res_x]="3840" [res_y]="2160" [fps]="15")
r5=([res_x]="1280" [res_y]="720"  [fps]="15")
r6=([res_x]="640"  [res_y]="480"  [fps]="15")

# Declare an indexed array to hold the names of the associative arrays
in_video_info=(r1 r2 r3 r4 r5 r6)

# Loop through each resolution and frame rate to generate output videos
for video_info in "${in_video_info[@]}"; do
    declare -n video=$video_info 
    output_file="$destination_directory/${out_file_name}_${video[res_x]}x${video[res_y]}_${video[fps]}fps_yuv420p_${bit_depth}bit.yuv"
    ffmpeg -i "$source_video" -vf "scale=${video[res_x]}:${video[res_y]}" -c:v rawvideo -pix_fmt yuv420p "$output_file" -hide_banner
    echo "Generated: $output_file"
done

echo "All videos generated successfully."
