

read -p "Masukkan file video (.mp4): " video
read -p "Masukkan durasi awal pemotongan video: " dua
read -p "Masukkan durasi akhir pemotongan video: " dui

echo "Sedang dikerjakan..."

echo "Membuat CODE..."
sleep 3

nama_file_output=""

python3 create_code.py > "${nama_file_output}"
echo "${nama_file_output}"

