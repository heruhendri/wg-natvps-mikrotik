# WireGuard NATVPS <-> MikroTik
Solusi interkoneksi jaringan lokal MikroTik ke NATVPS agar bisa saling akses/ping. Cocok untuk VPS berbasis NAT yang tidak punya IP Publik penuh.

## ⚠️ Syarat Utama
1. Di panel NATVPS: **Aktifkan fitur TUN/TAP**
2. Di panel NATVPS: **Buat Port Forwarding UDP `51820` ke port luar (misal `35000`)**

---

## 🚀 Cara Pasang di NATVPS
```bash
git clone https://github.com/[USERNAME]/wireguard-natvps-mikrotik.git
cd wireguard-natvps-mikrotik
chmod +x install-wg-server.sh
./install-wg-server.sh