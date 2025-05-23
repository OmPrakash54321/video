def sort_performance_data_in_place(file_path):
    # Read the data from the file
    with open(file_path, 'r') as file:
        lines = file.readlines()
    
    # Initialize a list to hold the parsed entries
    entries = []
    
    # Process each line
    for line in lines:
        # Split the line by '|' and strip whitespace
        parts = [part.strip() for part in line.split('|')]
        
        # Check if we have enough parts (at least 2 for a valid entry)
        if len(parts) >= 2:
            entry_name = parts[0]  # Name of the primitive
            last_column_value = parts[-1]  # Last column value
            
            try:
                # Convert last column value to float for sorting
                last_column_value_float = float(last_column_value)
            except ValueError:
                # Handle non-numeric values (e.g., inf, nan) by assigning a very low value
                last_column_value_float = float('-inf') if 'nan' in last_column_value else float('inf')
            
            # Append the entire line along with its last column value for sorting
            entries.append((parts, last_column_value_float))
    
    # Sort entries by the last column value in descending order
    sorted_entries = sorted(entries, key=lambda x: x[1], reverse=True)

    # Determine maximum widths for each column
    max_widths = [max(len(part[i]) for part, _ in sorted_entries) for i in range(len(sorted_entries[0][0]))]

    # Write sorted results back to the same file with aligned columns
    with open(file_path, 'w') as file:
        for entry_parts, _ in sorted_entries:
            formatted_line = ' | '.join(part.ljust(max_widths[i]) for i, part in enumerate(entry_parts))
            file.write(formatted_line + '\n')

#Example usage
file_path = '/home/mcw/Downloads/Video/qcs_folders/x265_testbench.txt'  # Replace with your actual file path

# Call the function to sort and overwrite results in the same file
sort_performance_data_in_place(file_path)

print(f"Sorted results have been written back to {file_path}.")
