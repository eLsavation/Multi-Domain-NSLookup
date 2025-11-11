#!/bin/bash

# --- KONFIGURASI ---
# File input yang berisi daftar domain
INPUT_FILE="list-domain.txt"
# Alamat IP server DNS yang akan ditanya
DNS_SERVER="8.8.8.8"
# Nama file output untuk domain yang berhasil
SUCCESS_FILE="sukses.txt"
# Nama file output untuk domain yang gagal
FAILED_FILE="gagal.txt"
# -------------------

# Periksa apakah file input ada
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File input '$INPUT_FILE' tidak ditemukan."
    exit 1
fi

# Kosongkan file output sebelum memulai untuk memastikan hasil selalu baru
> "$SUCCESS_FILE"
> "$FAILED_FILE"

echo "Memulai proses nslookup untuk domain di '$INPUT_FILE'..."
echo "Menggunakan DNS Server: $DNS_SERVER"
echo "--------------------------------------------------------"

# Baca setiap domain dari file input
while IFS= read -r domain; do
    # Menjalankan nslookup dan memeriksa outputnya secara langsung
    # 2>&1 digunakan untuk memastikan pesan error (seperti NXDOMAIN) juga ditangkap
    if nslookup "$domain" "$DNS_SERVER" 2>&1 | grep -q "NXDOMAIN"; then
        # Jika output mengandung "NXDOMAIN", domain dianggap gagal
        echo "GAGAL: $domain"
        echo "$domain" >> "$FAILED_FILE"
    else
        # Jika tidak, domain dianggap sukses
        echo "SUKSES: $domain"
        echo "$domain" >> "$SUCCESS_FILE"
    fi
done < "$INPUT_FILE"

echo "--------------------------------------------------------"
echo "Proses selesai."
echo "Domain yang berhasil disimpan di: $SUCCESS_FILE"
echo "Domain yang gagal (NXDOMAIN) disimpan di: $FAILED_FILE"
