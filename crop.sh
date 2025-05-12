#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_video> <output_video>"
    exit 1
fi

input="$1"
output="$2"

read width height <<< $(ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=x "$input" | tr 'x' ' ')

crop_w=$width
crop_h=$(( width * 5 / 4 ))

if [ $crop_h -gt $height ]; then
    crop_h=$height
    crop_w=$(( height * 4 / 5 ))
fi

x=$(( (width - crop_w) / 2 ))
y=$(( (height - crop_h) / 2 ))

ffmpeg -i "$input" -filter:v "crop=${crop_w}:${crop_h}:${x}:${y}" -c:a copy "$output"
