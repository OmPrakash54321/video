#!/bin/bash
presets=("ultrafast" "medium" "slower")
Dir_PATH=/home/mcw/Downloads/Video/perf_data
video=/ramdisk/1920x1080_500f_Samsung_Power_of_Curve_4K_Demo.yuv
for preset in "${presets[@]}"
do
    echo "$preset"
    count=1
    while [ "$count" -gt 0 ]
    do
        while true; do free -m | awk 'NR==2{printf "%.2f\n", $3*100/$2 }' >> "$Dir_PATH"/x265_8bit_memory_"$preset"_"$count".csv; sleep 1; done &    
        mem=$!
        sleep 10
        while true; do top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' >>  "$Dir_PATH"/x265_8bit_CPU_"$preset"_"$count".csv ; sleep 1; done &
        cpu=$!  

        start_time=$( date +%s.%N )
        number=0
        while [ "$number" -lt "$count" ]
        do
            x265 --input $video --input-res 1920x1080 --fps 60 --preset "$preset" -o "$Dir_PATH"/videos/out_"$number".hevc >> "$Dir_PATH"/x265_8bit_log_"$preset"_"$count".txt 2>&1 & 
            pids["$number"]=$!
            let "number++"
        done

        for pid in "${pids[@]}"; do
            wait "$pid"
        done

        elapsed_time=$( date +%s.%N --date="$start_time seconds ago" )
        echo "$elapsed_time" > "$Dir_PATH"/x265_8bit_time_"$preset"_"$count".csv

        kill -9 "$cpu"
        kill -9 "$mem"

        #compare the FPS
        grep -r "fps)" "$Dir_PATH"/x265_8bit_log_"$preset"_"$count".txt | sed 's/(/ /g' | awk '{print $6}' | awk -F '.' '{print $1}' > "$Dir_PATH"/fps_result.txt
        #
        fps_number=0
        for data in `cat $Dir_PATH/fps_result.txt`
        do
            if [ "$data" -ge 60 ]
            then
                echo "$data"
                let "fps_number++"
            else
                let "count--"               
                echo "${preset}: Num of Live channels sustained is ${count}" >> "$Dir_PATH"/x265_8bit_NumofLive_test_result.txt
                echo "$count" >> "$Dir_PATH"/x265_8bit_NumofLive.txt
                if [ "$count" -eq 0 ]
                then
                    echo "**********************"
                    CPU=$(awk -v col=1 '{if($col != "") {sum+=$col; count++}} END{print sum/count}' "$Dir_PATH"/x265_8bit_CPU_"$preset"_1.csv )
                    memory_max=$(awk 'BEGIN{max = 0}{if($1 > max) max = $1}END{print max}' "$Dir_PATH"/x265_8bit_memory_"$preset"_1.csv)
                    memory_min=$(awk 'BEGIN{min = 999999999}{if($1 < min) min = $1}END{print min}' "$Dir_PATH"/x265_8bit_memory_"$preset"_1.csv)
                    memory=$(echo "$memory_max-$memory_min" | bc)
                else
                    echo "################"
                    CPU=$(awk -v col=1 '{if($col != "") {sum+=$col; count++}} END{print sum/count}' "$Dir_PATH"/x265_8bit_CPU_"$preset"_"$count".csv )
                    memory_max=$(awk 'BEGIN{max = 0}{if($1 > max) max = $1}END{print max}' "$Dir_PATH"/x265_8bit_memory_"$preset"_"$count".csv)
                    memory_min=$(awk 'BEGIN{min = 999999999}{if($1 < min) min = $1}END{print min}' "$Dir_PATH"/x265_8bit_memory_"$preset"_"$count".csv)
                    memory=$(echo "$memory_max-$memory_min" | bc)
                fi
                echo "$CPU, $memory" >> x265_cpu.txt
                count=0
                break
            fi
        done
        
        if [ "$fps_number" -eq "$count" ] && [ "$count" -gt 0 ]
        then
            #rm -r "$Dir_PATH"/x265_8bit_memory_"$preset"_"$count".csv
            #rm -r "$Dir_PATH"/x265_8bit_CPU_"$preset"_"$count".csv
            rm -r "$Dir_PATH"/x265_8bit_log_"$preset"_"$count".txt
            rm -r "$Dir_PATH"/x265_8bit_time_"$preset"_"$count".csv
            rm -r "$Dir_PATH"/fps_result.txt
            let "count++"
        fi
    done
    
    rm -r "$Dir_PATH"/fps_result.txt
done
