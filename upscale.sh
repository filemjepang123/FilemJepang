#!/bin/bash

# Cek jumlah argumen
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_video> <output_video>"
    exit 1
fi

input="$1"
output="$2"

# Proses meningkatkan kualitas tanpa ubah ukuran
ffmpeg -i "$input" -c:v libx264 -crf 0 -preset slow -c:a copy "$output"
