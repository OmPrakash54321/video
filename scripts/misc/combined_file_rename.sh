for file in 8bit_perf_4k_*.txt; do
    mv -- "$file" "${file#8bit_perf_4k_}"
done
