import re
from collections import defaultdict

def parse_perf_file(input_file, output_file):
    # Dictionary to store event data
    events_data = defaultdict(list)
    current_event = None

    with open(input_file, 'r') as file:
        for line in file:
            # Check for event name (e.g., "Samples: 7K of event 'cpu-cycles'")
            event_match = re.match(r"# Samples:.*of event '(.*?)'", line)
            if event_match:
                current_event = event_match.group(1)
                continue
            
            # Parse function data (e.g., "11.86%  x264     x264               [.] refine_subpel")
            if current_event:
                function_match = re.match(r"\s*(\d+\.\d+)%.*\[.\]\s+(.*)", line)
                if function_match:
                    percentage = float(function_match.group(1))
                    function_name = function_match.group(2).strip()
                    events_data[current_event].append((percentage, function_name))

    # Write top 10 functions per event to the output file
    with open(output_file, 'w') as out_file:
        for event, functions in events_data.items():
            out_file.write(f"{event}\n")
            top_functions = sorted(functions, key=lambda x: x[0], reverse=True)[:10000]
            for percentage, function_name in top_functions:
                out_file.write(f"{percentage:.2f}%, {function_name}\n")
            out_file.write("\n")

# Example usage
input_file = "/home/mcw/Downloads/MCW/Video/qcs_folders/perf_compare_decoder_with_without_asm_apr29/x264_profile_logs/profile_logs/perf_report_with_simd_x264.txt"  # Replace with your input file path
output_file = "/home/mcw/Downloads/MCW/Video/qcs_folders/perf_compare_decoder_with_without_asm_apr29/x264_profile_logs/profile_logs/top1000.txt"  # Replace with your desired output file path
parse_perf_file(input_file, output_file)
