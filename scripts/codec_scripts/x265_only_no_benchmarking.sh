#!/bin/bash

INPUT_DIR="/home/mcw/Downloads/Video/video_input"
video="out_ff.y4m"
preset="medium"
output_file="/home/mcw/Downloads/Video/video_output/out.hevc"
log_file="/home/mcw/Downloads/Video/video_output/encode.log"

x265 --input "$INPUT_DIR/$video" --preset "$preset" --psnr --ssim --output "$output_file" > "$log_file"