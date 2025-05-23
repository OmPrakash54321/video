#!/bin/bash

# Base directory to start from
BASE_DIR="/home/root/new_testing/encoded_new/x265"

# Output CSV file to store results
OUTPUT_CSV="/home/root/new_testing/encoded_new/metrics_encode_4k265_results.csv"

# Create CSV file with headers if it doesn't exist
if [ ! -f "$OUTPUT_CSV" ]; then
    echo "Log Directory,Log File,FPS,Bitrate (kbps),SSIM Mean Y,PSNR Mean Y" > "$OUTPUT_CSV"
fi

# Recursive function to process log files
process_logs() {
    local LOG_DIR=$1

    if [ -d "$LOG_DIR" ]; then
        echo "Processing logs in directory: $LOG_DIR"
        
        # Variables to calculate averages
        TOTAL_FPS=0
        TOTAL_BITRATE=0
        TOTAL_SSIM=0
        TOTAL_PSNR=0
        FILE_COUNT=0

        # Loop through all .log files in the directory (excluding encoding_pids.log)
        for LOG_FILE in "$LOG_DIR"/*.log; do
            if [[ -f "$LOG_FILE" && ! "$LOG_FILE" =~ encoding_pids.log ]]; then
                # Extract FPS
                FPS=$(grep "encoded" "$LOG_FILE" | awk -F'[()]' '{print $2}' | awk '{print $1}' | head -n 1)

                # Extract Bitrate (in kbps)
                BITRATE=$(grep "encoded" "$LOG_FILE" | awk -F', ' '{for (i=1; i<=NF; i++) if ($i ~ /kb\/s/) print $(i-1)}' | head -n 1)

                # Extract PSNR Mean Y
                PSNR=$(grep "Global PSNR:" "$LOG_FILE" | awk '{print $(NF)}' | head -n 1)

                # Extract SSIM Mean Y
                SSIM=$(grep "SSIM Mean Y:" "$LOG_FILE" | awk '{print $(NF-1)}' | head -n 1)

                # Print individual values
                echo "Log File: $(basename "$LOG_FILE")"
                echo "FPS: $FPS"
                echo "Bitrate: $BITRATE kbps"
                echo "SSIM Mean Y: $SSIM"
                echo "PSNR Mean Y: $PSNR"
                echo "-----------------------------"

                # Add to totals for averaging
                TOTAL_FPS=$(echo "$TOTAL_FPS + $FPS" | bc)
                TOTAL_BITRATE=$(echo "$TOTAL_BITRATE + $BITRATE" | bc)
                TOTAL_SSIM=$(echo "$TOTAL_SSIM + $SSIM" | bc)
                TOTAL_PSNR=$(echo "$TOTAL_PSNR + $PSNR" | bc)
                ((FILE_COUNT++))

                # Append the individual results to CSV
                echo "$LOG_DIR,$(basename "$LOG_FILE"),$FPS,$BITRATE,$SSIM,$PSNR" >> "$OUTPUT_CSV"
            fi
        done

        # Calculate averages if there were files processed
        if [ "$FILE_COUNT" -gt 0 ]; then
            AVG_FPS=$(echo "scale=2; $TOTAL_FPS / $FILE_COUNT" | bc)
            AVG_BITRATE=$(echo "scale=2; $TOTAL_BITRATE / $FILE_COUNT" | bc)
            AVG_SSIM=$(echo "scale=6; $TOTAL_SSIM / $FILE_COUNT" | bc)
            AVG_PSNR=$(echo "scale=3; $TOTAL_PSNR / $FILE_COUNT" | bc)

            # Print averages for the current set of files
            echo "-----------------------------"
            echo "Averages for directory $LOG_DIR"
            echo "Average FPS: $AVG_FPS"
            echo "Average Bitrate: $AVG_BITRATE kbps"
            echo "Average SSIM Mean Y: $AVG_SSIM"
            echo "Average PSNR Mean Y: $AVG_PSNR"
            echo "-----------------------------"

            # Append averages to CSV
            echo "$LOG_DIR,Averages,$AVG_FPS,$AVG_BITRATE,$AVG_SSIM,$AVG_PSNR" >> "$OUTPUT_CSV"
        else
            echo "No .log files found in $LOG_DIR"
        fi
        
        echo "" >> "$OUTPUT_CSV"
    else
        echo "Warning: Directory $LOG_DIR not found, skipping..."
    fi
}

# Recursively find all log directories and process them
find "$BASE_DIR" -type d -name "log" | while read LOG_DIR; do
    process_logs "$LOG_DIR"
done

echo "Averages extracted and saved to $OUTPUT_CSV."

