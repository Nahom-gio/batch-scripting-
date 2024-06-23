#!/bin/bash

# Function to display the main menu using whiptail
display_menu() {
    CHOICE=$(whiptail --title "CSV Data Analysis Tool" --menu "Choose an option" 15 60 10 \
    "1" "Display row and column count" \
    "2" "List unique values in a column" \
    "3" "Show column names (header)" \
    "4" "Find minimum and maximum values" \
    "5" "Find most frequent value" \
    "6" "Calculate summary statistics" \
    "7" "Filter and extract data" \
    "8" "Sort the CSV file" \
    "9" "Save analysis results" \
    "10" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) enter_csv_and_run display_row_col_count ;;
        2) enter_csv_and_run list_unique_values ;;
        3) enter_csv_and_run display_column_names ;;
        4) enter_csv_and_run find_min_max ;;
        5) enter_csv_and_run find_most_frequent ;;
        6) enter_csv_and_run calculate_summary_stats ;;
        7) enter_csv_and_run filter_and_extract_data ;;
        8) enter_csv_and_run sort_csv_file ;;
        9) enter_csv_and_run save_analysis_results ;;
        10) exit 0 ;;
        *) whiptail --msgbox "Invalid choice. Please try again." 8 45 ;;
    esac
}

# Function to prompt for CSV file and run the provided function if the file is valid
enter_csv_and_run() {
    whiptail --title "CSV File Path" --inputbox "Enter the CSV file path:" 8 78 2>temp.txt
    csv_file=$(<temp.txt)
    if validate_csv_file "$csv_file"; then
        $1 "$csv_file"
    fi
}

# Function to validate the CSV file
validate_csv_file() {
    csv_file=$1

    if [ ! -f "$csv_file" ]; then
        whiptail --title "Error" --msgbox "File does not exist." 8 45
        return 1
    elif [ ! -r "$csv_file" ]; then
        whiptail --title "Error" --msgbox "File is not readable." 8 45
        return 1
    elif [ $(head -n 1 "$csv_file" | tr -cd ',' | wc -c) -lt 1 ]; then
        whiptail --title "Error" --msgbox "File does not contain expected columns." 8 45
        return 1
    fi

    return 0
}

# Function to display row and column count
display_row_col_count() {
    csv_file=$1
    row_count=$(wc -l < "$csv_file")
    col_count=$(head -n 1 "$csv_file" | tr -cd ',' | wc -c)
    total_cols=$((col_count + 1))

    whiptail --msgbox "The CSV file has $row_count rows and $total_cols columns." 8 45
}

# Function to list unique values in a column
list_unique_values() {
    csv_file=$1

    column_index=$(whiptail --title "Column Selection" --inputbox "Enter the column number to list unique values:" 8 78 3>&1 1>&2 2>&3)
    unique_values=$(cut -d',' -f$column_index "$csv_file" | sort -u)
    whiptail --msgbox "Unique values in column $column_index:\n$unique_values" 20 78
}

# Function to display column names (header)
display_column_names() {
    csv_file=$1
    header=$(head -n 1 "$csv_file")
    whiptail --msgbox "Column names (header):\n$header" 8 78
}

# Function to find minimum and maximum values
find_min_max() {
    csv_file=$1

    column_index=$(whiptail --title "Column Selection" --inputbox "Enter the column number to find min and max:" 8 78 3>&1 1>&2 2>&3)
    column_data=$(cut -d',' -f$column_index "$csv_file")
    numeric_values=$(echo "$column_data" | grep -E '^-?[0-9]+([.][0-9]+)?$')

    if [ -n "$numeric_values" ]; then
        min_value=$(echo "$numeric_values" | sort -n | head -n 1)
        max_value=$(echo "$numeric_values" | sort -n | tail -n 1)
        whiptail --msgbox "Minimum value in column $column_index: $min_value\nMaximum value in column $column_index: $max_value" 8 78
    else
        whiptail --msgbox "Column $column_index does not contain numeric values." 8 45
    fi
}

# Function to find the most frequent value
find_most_frequent() {
    csv_file=$1

    column_index=$(whiptail --title "Column Selection" --inputbox "Enter the column number to find the most frequent value:" 8 78 3>&1 1>&2 2>&3)
    most_frequent=$(cut -d',' -f$column_index "$csv_file" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')
    whiptail --msgbox "The most frequent value in column $column_index is: $most_frequent" 8 78
}

# Function to calculate summary statistics
calculate_summary_stats() {
    csv_file=$1

    column_index=$(whiptail --title "Column Selection" --inputbox "Enter the column number to calculate summary statistics:" 8 78 3>&1 1>&2 2>&3)
    values=$(cut -d',' -f$column_index "$csv_file")
    numeric_values=$(echo "$values" | grep -E '^-?[0-9]+([.][0-9]+)?$')

    if [ -n "$numeric_values" ]; then
        mean=$(echo "$numeric_values" | awk '{sum+=$1} END {print sum/NR}')
        median=$(echo "$numeric_values" | sort -n | awk '{a[i++]=$1} END {print a[int(i/2)]}')
        std_dev=$(echo "$numeric_values" | awk '{sum+=$1; sumsq+=$1*$1} END {print sqrt(sumsq/NR - (sum/NR)*(sum/NR))}')

        whiptail --msgbox "Summary statistics for column $column_index:\nMean: $mean\nMedian: $median\nStandard deviation: $std_dev" 8 78
    else
        whiptail --msgbox "Column $column_index does not contain numeric values." 8 45
    fi
}

# Function to filter and extract data
filter_and_extract_data() {
    csv_file=$1

    column_index=$(whiptail --title "Column Selection" --inputbox "Enter the column number to filter by:" 8 78 3>&1 1>&2 2>&3)
    filter_value=$(whiptail --title "Filter Value" --inputbox "Enter the value to filter by:" 8 78 3>&1 1>&2 2>&3)
    output_file="filtered_${csv_file}"

    awk -F',' -v col=$column_index -v val="$filter_value" '$col == val' "$csv_file" > "$output_file"
    whiptail --msgbox "Filtered data saved to $output_file" 8 45
}

# Function to sort the CSV file
sort_csv_file() {
    csv_file=$1

    sort_column=$(whiptail --title "Column Selection" --inputbox "Enter the column number to sort by:" 8 78 3>&1 1>&2 2>&3)
    output_file="sorted_${csv_file}"

    sort -t',' -k$sort_column,${sort_column}n "$csv_file" > "$output_file"
    whiptail --msgbox "CSV file sorted and saved as $output_file" 8 45
}

# Function to save analysis results
save_analysis_results() {
    csv_file=$1
    default_output_file="analysis_results.txt"

    user_output_file=$(whiptail --title "Output File Name" --inputbox "Enter the output file name (default is analysis_results.txt):" 8 78 3>&1 1>&2 2>&3)
    output_file=${user_output_file:-$default_output_file}

    if [ -f "$output_file" ]; then
        if ! whiptail --title "Overwrite?" --yesno "File exists. Do you want to overwrite?" 8 45; then
            whiptail --msgbox "Analysis results not saved." 8 45
            return
        fi
    fi

    echo "Saving analysis results to $output_file..." > "$output_file"

    row_count=$(wc -l < "$csv_file")
    let "row_count -= 1"
    col_count=$(head -n 1 "$csv_file" | tr -cd ',' | wc -c)
    total_cols=$((col_count + 1))

    echo "Row and column count:" >> "$output_file"
  echo "The CSV file has $row_count rows and $total_cols columns." >> "$output_file"
    echo "" >> "$output_file"

    echo "Column names (header):" >> "$output_file"
    head -n 1 "$csv_file" >> "$output_file"
    echo "" >> "$output_file"

    for ((i=1; i<=$total_cols; i++)); do
        echo "Unique values in column $i:" >> "$output_file"
        tail -n +2 "$csv_file" | cut -d',' -f$i | sort -u >> "$output_file"
        echo "" >> "$output_file"

        echo "Minimum and maximum values in column $i:" >> "$output_file"
        values=$(tail -n +2 "$csv_file" | cut -d',' -f$i)
        numeric_values=$(echo "$values" | grep -E '^-?[0-9]+([.][0-9]+)?$')
        if [ -n "$numeric_values" ]; then
            min_value=$(echo "$numeric_values" | sort -n | head -n 1)
            max_value=$(echo "$numeric_values" | sort -n | tail -n 1)
            echo "Minimum value: $min_value" >> "$output_file"
            echo "Maximum value: $max_value" >> "$output_file"
        else
            echo "Minimum value: N/A" >> "$output_file"
            echo "Maximum value: N/A" >> "$output_file"
        fi
        echo "" >> "$output_file"

        echo "Most frequent value in column $i:" >> "$output_file"
        tail -n +2 "$csv_file" | cut -d',' -f$i | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}' >> "$output_file"
        echo "" >> "$output_file"

        echo "Summary statistics for column $i:" >> "$output_file"
        if [ -n "$numeric_values" ]; then
            mean=$(echo "$numeric_values" | awk '{sum+=$1} END {print sum/NR}')
            median=$(echo "$numeric_values" | sort -n | awk '{a[i++]=$1} END {print a[int(i/2)]}')
            std_dev=$(echo "$numeric_values" | awk '{sum+=$1; sumsq+=$1*$1} END {print sqrt(sumsq/NR - (sum/NR)*(sum/NR))}')
            echo "Mean: $mean" >> "$output_file"
            echo "Median: $median" >> "$output_file"
            echo "Standard deviation: $std_dev" >> "$output_file"
        else
            echo "Mean: N/A" >> "$output_file"
            echo "Median: N/A" >> "$output_file"
            echo "Standard deviation: N/A" >> "$output_file"
        fi
        echo "" >> "$output_file"
    done

    whiptail --msgbox "Analysis results saved to $output_file." 8 45
}

# Main program loop
while true; do
    display_menu
done
