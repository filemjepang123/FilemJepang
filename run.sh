#!/bin/bash

# Meminta input file video
read -p "Masukkan file video (.mp4): " video

# Validasi file ada dan berekstensi .mp4
if [[ ! -f "${video}" ]]; then
    echo "File tidak ditemukan."
    exit 1
fi

if [[ ! "${video}" =~ \.mp4$ ]]; then
    echo "File harus berekstensi .mp4"
    exit 1
fi

# Meminta input durasi
read -p "Masukkan durasi awal pemotongan video: " dua
read -p "Masukkan durasi akhir pemotongan video: " dui

echo "[*] Sedang dikerjakan..."
echo "[*] Membuat CODE..."

# Memeriksa keberadaan create_code.py
if [[ ! -f "create_code.py" ]]; then
    echo "File create_code.py tidak ditemukan."
    exit 1
fi

output=$(python3 create_code.py)
if [[ -z "${output}" ]]; then
    echo "Gagal mendapatkan kode dari create_code.py."
    exit 1
fi

echo "[*] Memotong video..."
bash cut.sh -i "${video}" -da "${dua}" -di "${dui}" -o "tmp.mp4"
if [[ $? -ne 0 ]]; then
    echo "Gagal memotong video."
    exit 1
fi

echo "[*] Mengcrop video..."
bash crop.sh "tmp.mp4" "tmp_2.mp4"
if [[ $? -ne 0 ]]; then
    echo "Gagal mengcrop video."
    exit 1
fi

echo "[*] Meningkatkan kualitas video..."
bash upscale.sh "tmp_2.mp4" "${output}.mp4"
if [[ $? -ne 0 ]]; then
    echo "Gagal meningkatkan kualitas video."
    exit 1
fi

echo "[+] Selesai."
echo "[*] Memberikan file tidak penting..."
sleep 3
rm *tmp
echo "[+] Video berhasil dibuat dengan nama: ${output}"
echo ""
echo "[*] Semoga harimu menyenangkan :)"
