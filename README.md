
---

```markdown
# wg-natvps-mikrotik
Solusi interkoneksi jaringan menggunakan WireGuard antara **NATVPS** dan **MikroTik**. Memungkinkan kamu mengakses/melakukan ping ke perangkat di jaringan lokal MikroTik langsung dari NATVPS, meskipun VPS kamu tidak memiliki IP Publik penuh.

## 📋 Persyaratan Wajib
Sebelum memulai, pastikan kamu sudah melakukan pengaturan ini di panel penyedia NATVPS kamu:
1.  ✅ **Aktifkan fitur TUN/TAP** (biasanya ada di pengaturan jaringan/khusus kernel).
2.  ✅ **Buat Port Forwarding UDP**: Arahkan port luar (misal: `35000`) ke port dalam VPS: `51820`.
    > Contoh: `35000 → 51820 (UDP)`
3.  ✅ Catat **IP Publik NATVPS** dan **Nomor Port Luar** yang sudah dibuat.

---

## 🚀 LANGKAH 1: Instalasi di Sisi NATVPS
Jalankan perintah berikut ini secara berurutan di dalam terminal NATVPS kamu:

### 1.1 Unduh & Beri Izin Skrip
```bash
# Unduh repositori
git clone https://github.com/[USERNAME_ANDA]/wg-natvps-mikrotik.git

# Masuk ke folder
cd wg-natvps-mikrotik

# Beri hak eksekusi ke skrip installer
chmod +x install-wg-server.sh
```

### 1.2 Jalankan Installer
```bash
./install-wg-server.sh
```

### 1.3 Isi Data Sesuai Instruksi
Saat berjalan, skrip akan meminta input, isi sesuai kondisi jaringan kamu:
1.  **Masukkan IP Jaringan Lokal MikroTik**: Isi dengan rentang IP LAN kamu.
    > Contoh: `192.168.88.0/24`
2.  **Masukkan Port Forwarding Luar NATVPS**: Isi port yang kamu buat di panel NATVPS tadi.
    > Contoh: `35000`
3.  **Masukkan Kunci Publik dari MikroTik**: *Kosongkan dulu atau isi sembarang*, nanti kamu akan mengubahnya ulang setelah dapat kunci dari MikroTik.

> ⚠️ **PENTING:** Di akhir proses, skrip akan menampilkan informasi. **SALIN DAN SIMPAN** nilai berikut:
> - `Kunci Publik Server VPS`
> - `IP Server VPN` (biasanya `10.9.0.1`)

---

## ⚙️ LANGKAH 2: Konfigurasi di Sisi MikroTik
Sekarang kita atur sisi router MikroTik agar bisa terhubung ke NATVPS.

### 2.1 Edit Berkas Skrip
Buka berkas `mikrotik-script.rsc` menggunakan notepad atau editor teks, lalu ubah bagian di paling atas sesuai data kamu:
```routeros
:local VPS_PUB_KEY "ISI_KUNCI_PUBLIK_SERVER_VPS_DISINI"   ⬅️ Isi kunci yang disimpan di Langkah 1.3
:local VPS_IP "ISI_IP_PUBLIK_NATVPS_DISINI"               ⬅️ Contoh: 203.0.123.45
:local VPS_PORT "ISI_PORT_FORWARDING_DISINI"              ⬅️ Contoh: 35000
:local LOCAL_NET "192.168.88.0/24"                        ⬅️ Sesuaikan dengan jaringan LAN kamu
```

### 2.2 Jalankan Skrip di MikroTik
1.  Buka aplikasi **Winbox** dan masuk ke router kamu.
2.  Buka menu **Terminal**.
3.  Salin **semua isi berkas `mikrotik-script.rsc`** yang sudah diedit tadi, lalu tempelkan ke jendela Terminal dan tekan Enter.

### 2.3 Simpan Kunci MikroTik
Setelah skrip selesai berjalan, layar akan memunculkan pesan seperti ini:
```text
>>> Kunci Publik MikroTik: abcdefghijklmnopqrstuvwxyz1234567890=
```
**SALIN KUNCI PUBLIK TERSEBUT**, kita butuh untuk dikembalikan ke sisi NATVPS.

---

## 🔄 LANGKAH 3: Sinkronisasi Kunci (Penting!)
Kita perlu memasukkan kunci publik MikroTik ke konfigurasi Server NATVPS agar koneksi jalan.

### 3.1 Edit Konfigurasi Server NATVPS
Kembali ke terminal NATVPS, edit berkas konfigurasi:
```bash
nano /etc/wireguard/wg0.conf
```

Cari baris bagian `[Peer]`, ubah nilai `PublicKey` yang tadi kita isi sembarang dengan **Kunci Publik MikroTik** yang baru saja kamu dapatkan.

Contoh hasil akhir:
```ini
[Peer]
PublicKey = abcdefghijklmnopqrstuvwxyz1234567890=   ⬅️ Ini kunci dari MikroTik
AllowedIPs = 10.9.0.2/32, 192.168.88.0/24
```
Simpan dengan `Ctrl+O`, lalu keluar dengan `Ctrl+X`.

### 3.2 Restart Layanan WireGuard
```bash
systemctl restart wg-quick@wg0
```

---

## ✅ LANGKAH 4: Tes Koneksi
Sekarang saatnya memastikan semuanya berjalan lancar.

### 4.1 Cek Status Handshake
Di NATVPS, ketik perintah:
```bash
wg show
```
> ✅ **Tanda Berhasil:** Ada tulisan `latest handshake: 1m 30s ago` (ada waktunya).
> ❌ **Gagal:** Tulisan `latest handshake` tidak ada / kosong. Cek lagi Port Forwarding atau TUN/TAP.

### 4.2 Tes Ping Jaringan Lokal
Coba ping IP Router MikroTik atau IP perangkat di jaringan lokal kamu langsung dari NATVPS:
```bash
ping 192.168.88.1   ⬅️ Ganti dengan IP LAN kamu
```

Jika balasan muncul, **berarti instalasi dan konfigurasi BERHASIL! 🎉**

---

## 🛠️ Pemecahan Masalah
- **Tidak ada Handshake:** Cek ulang apakah port forwarding UDP sudah benar dan fitur TUN/TAP sudah aktif.
- **Ada Handshake tapi tidak bisa Ping:** Cek aturan Firewall di MikroTik (bagian `Filter Rules`) dan pastikan `IP Forwarding` aktif di kedua sisi.
- **Konfigurasi hilang setelah restart:** Pastikan baris rute `ip route add ...` sudah masuk ke dalam berkas `/etc/rc.local` dan berkas tersebut bisa dieksekusi (`chmod +x /etc/rc.local`).

---

## 📂 Struktur Berkas
- `install-wg-server.sh`: Skrip utama otomatisasi instalasi sisi Server.
- `mikrotik-script.rsc`: Skrip konfigurasi lengkap untuk sisi MikroTik.
- `wg0.conf.example`: Contoh konfigurasi manual jika ingin mengatur sendiri.
- `README.md`: Panduan ini.
```

