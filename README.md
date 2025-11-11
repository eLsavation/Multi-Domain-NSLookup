# 🧠 Multi NSLookup Script

**Multi NSLookup** adalah skrip Bash sederhana namun powerful untuk melakukan *bulk DNS lookup* terhadap daftar domain secara otomatis.  
Skrip ini membaca daftar domain dari file, melakukan `nslookup` menggunakan server DNS yang ditentukan, dan memisahkan hasilnya ke dalam file *sukses* dan *gagal*.

---

## 🚀 Fitur

- 🔁 Mengecek banyak domain sekaligus secara otomatis  
- 🧩 Menggunakan server DNS yang bisa dikonfigurasi  
- 📂 Hasil terpisah untuk domain yang valid dan tidak valid  
- 🧹 Menghapus hasil lama sebelum setiap eksekusi untuk menjaga data tetap bersih  

---

## ⚙️ Konfigurasi

Edit variabel berikut di dalam file [`multi-nslookup.sh`](multi-nslookup.sh):

```bash
INPUT_FILE="list-domain.txt"     # File input berisi daftar domain
DNS_SERVER="8.8.8.8"       # Server DNS yang digunakan untuk lookup
SUCCESS_FILE="sukses.txt"       # Output domain yang berhasil
FAILED_FILE="gagal.txt"         # Output domain yang gagal (NXDOMAIN)
```

---

## 🧾 Cara Penggunaan

1. Siapkan file `list-domain.txt` yang berisi daftar domain (satu domain per baris).
2. Pastikan file `multi-nslookup.sh` memiliki izin eksekusi:
   ```bash
   chmod +x multi-nslookup.sh
   ```
3. Jalankan skrip:
   ```bash
   ./multi-nslookup.sh
   ```
4. Lihat hasil:
   - ✅ `sukses.txt` → berisi domain yang berhasil di-*resolve*
   - ❌ `gagal.txt` → berisi domain yang gagal (NXDOMAIN)

---

## 🧰 Contoh Output

```
Memulai proses nslookup untuk domain di 'list-domain.txt'...
Menggunakan DNS Server: 8.8.8.8
--------------------------------------------------------
SUKSES: example.com
GAGAL: invalid-domain.xyz
--------------------------------------------------------
Proses selesai.
Domain yang berhasil disimpan di: sukses.txt
Domain yang gagal (NXDOMAIN) disimpan di: gagal.txt
```

---

## 🧑‍💻 Requirements

- Sistem operasi: Linux / macOS / WSL (Windows Subsystem for Linux)
- Tools bawaan: `bash`, `nslookup`, `grep`


---

> "Automate repetitive tasks — so you can focus on smarter things."
