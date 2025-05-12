#!/bin/bash

# Function to display script usage
usage() {
    echo "Usage: $0 -i <input_video> -da <start_duration> -di <end_duration> [-o <output_file>]"
    echo "Format: Durations in MM:SS or HH:MM:SS (e.g., '01:30' or '00:01:30')"
    echo "Example: $0 -i video.mp4 -da 00:00 -di 00:30 -o output.mp4"
    exit 1
}

# Function to validate and convert duration format
validate_and_convert_duration() {
    local duration=$1
    local arg_name=$2

    # Validate MM:SS or HH:MM:SS format
    if [[ $duration =~ ^([0-9]{2}):([0-5][0-9])$ ]]; then
        # MM:SS format, prepend 00:
        echo "00:${duration}"
    elif [[ $duration =~ ^([0-9]{1,2}):([0-5][0-9]):([0-5][0-9])$ ]]; then
        # HH:MM:SS format, validate hours
        local hours=${BASH_REMATCH[1]}
        if (( hours >= 0 && hours <= 99 )); then
            echo "${duration}"
        else
            echo "Error: Invalid hours in $arg_name (must be 00-99): $duration" >&2
            exit 1
        fi
    else
        echo "Error: Invalid duration format in $arg_name. Must be MM:SS or HH:MM:SS, found: $duration" >&2
        exit 1
    fi
}

# Check if ffmpeg is installed
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: ffmpeg is not installed. Please install ffmpeg first." >&2
    exit 1
fi

# Check if arguments are provided
if [ $# -eq 0 ]; then
    usage
fi

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i) input_video="$2"; shift ;;
        -da) start_duration="$2"; shift ;;
        -di) end_duration="$2"; shift ;;
        -o) output_file="$2"; shift ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
    shift
done

# Validate inputs
if [ -z "$input_video" ] || [ -z "$start_duration" ] || [ -z "$end_duration" ]; then
    echo "Error: Arguments -i, -da, and -di are required." >&2
    usage
fi

# Check if input file exists
if [ ! -f "$input_video" ]; then
    echo "Error: Input file $input_video not found." >&2
    exit 1
fi

# Set default output file if -o is not provided
output_file=${output_file:-"output.mp4"}

# Validate and convert durations
start_converted=$(validate_and_convert_duration "$start_duration" "-da")
end_converted=$(validate_and_convert_duration "$end_duration" "-di")

# Convert durations to seconds for time order check
start_sec=$(echo "$start_converted" | awk -F: '{print ($1*3600)+($2*60)+$3}')
end_sec=$(echo "$end_converted" | awk -F: '{print ($1*3600)+($2*60)+$3}')

if [ "$start_sec" -ge "$end_sec" ]; then
    echo "Error: Start duration ($start_duration) must be less than end duration ($end_duration)." >&2
    exit 1
fi

# Ensure output file has .mp4 extension
if [[ ! "$output_file" =~ \.mp4$ ]]; then
    output_file="${output_file}.mp4"
fi

# Cut the video
echo "Cutting video from $start_duration to $end_duration..."

if ffmpeg -i "$input_video" -ss "$start_converted" -to "$end_converted" -c:v copy -c:a copy "$output_file" -y -loglevel error >/dev/null 2>&1; then
    echo "Video successfully saved as $output_file"
else
    echo "Error: Failed to cut video. Check input or durations." >&2
    exit 1
fi

echo "Finished!"
