#!/bin/bash

# Function to display script usage
usage() {
    echo "Usage: $0 -i <input_video> -da <start_durations> -di <end_durations> [-o <output_base>]"
    echo "Format: Durations in MM:SS or HH:MM:SS (e.g., '01:30' or '00:01:30')"
    echo "Example: $0 -i video.mp4 -da '00:00 02:30' -di '00:00:30 00:03:00' -o scene"
    exit 1
}

# Function to validate and convert duration format
validate_and_convert_duration() {
    local duration=$1
    local arg_name=$2
    local index=$3

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
            echo "Error: Invalid hours in $arg_name index $index (must be 00-99): $duration" >&2
            exit 1
        fi
    else
        echo "Error: Invalid duration format in $arg_name index $index. Must be MM:SS or HH:MM:SS, found: $duration" >&2
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
        -da) IFS=' ' read -r -a start_durations <<< "$2"; shift ;;
        -di) IFS=' ' read -r -a end_durations <<< "$2"; shift ;;
        -o) output_base="$2"; shift ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
    shift
done

# Validate inputs
if [ -z "$input_video" ] || [ ${#start_durations[@]} -eq 0 ] || [ ${#end_durations[@]} -eq 0 ]; then
    echo "Error: Arguments -i, -da, and -di are required." >&2
    usage
fi

# Check if input file exists
if [ ! -f "$input_video" ]; then
    echo "Error: Input file $input_video not found." >&2
    exit 1
fi

# Check if start and end durations match in count
if [ ${#start_durations[@]} -ne ${#end_durations[@]} ]; then
    echo "Error: Number of start (-da) and end (-di) durations must match." >&2
    exit 1
fi

# Set default output base if -o is not provided
output_base=${output_base:-"output_scene"}

# Validate and convert durations, check time order
start_durations_converted=()
end_durations_converted=()
for i in "${!start_durations[@]}"; do
    start_durations_converted+=("$(validate_and_convert_duration "${start_durations[i]}" "-da" "$((i+1))")")
    end_durations_converted+=("$(validate_and_convert_duration "${end_durations[i]}" "-di" "$((i+1))")")

    # Convert durations to seconds for time order check
    start_sec=$(echo "${start_durations_converted[i]}" | awk -F: '{print ($1*3600)+($2*60)+$3}')
    end_sec=$(echo "${end_durations_converted[i]}" | awk -F: '{print ($1*3600)+($2*60)+$3}')

    if [ "$start_sec" -ge "$end_sec" ]; then
        echo "Error: Start duration (${start_durations[i]}) must be less than end duration (${end_durations[i]}) at index $((i+1))." >&2
        exit 1
    fi
done

# Loop to cut video into scenes
for ((i=0; i<${#start_durations_converted[@]}; i++)); do
    start=${start_durations_converted[i]}
    end=${end_durations_converted[i]}
    output="${output_base}_$((i+1)).mp4"

    echo "Cutting scene $((i+1)): from ${start_durations[i]} to ${end_durations[i]}..."

    # Run ffmpeg with minimal logging
    if ffmpeg -i "$input_video" -ss "$start" -to "$end" -c:v copy -c:a copy "$output" -y -loglevel error >/dev/null 2>&1; then
        echo "Scene $((i+1)) successfully saved as $output"
    else
        echo "Error: Failed to cut scene $((i+1)). Check input or durations." >&2
        exit 1
    fi
done

echo "Finished cutting all scenes!"
