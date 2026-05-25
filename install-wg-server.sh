#!/bin/bash
set -e

# ==============================================
# WireGuard Server Installer for NATVPS
# Repo: https://github.com/heruhendri/WG-NATVPS-MIKROTIK
# ==============================================

# Warna output
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Memulai instalasi WireGuard di NATVPS...${NC}"

# Update sistem & pasang WireGuard
apt update -y
apt install -y wireguard iptables

# Aktifkan penerusan IP
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
sysctl -p /etc/sysctl.d/99-ipforward.conf

# Masuk direktori konfigurasi
cd /etc/wireguard
umask 077

# Buat kunci jika belum ada
if [ ! -f privatekey ]; then
    echo -e "${GREEN}>>> Membuat pasangan kunci kriptografi...${NC}"
    wg genkey | tee privatekey | wg pubkey > publickey
fi

# Baca kunci
PRIV_KEY=$(cat privatekey)
PUB_KEY=$(cat publickey)

# Tanya konfigurasi dasar
read -p "Masukkan IP Jaringan Lokal MikroTik (contoh: 192.168.88.0/24): " LOCAL_NET
read -p "Masukkan Port Forwarding Luar NATVPS (contoh: 35000): " EXT_PORT
read -p "Masukkan Kunci Publik dari MikroTik: " MT_PUB_KEY

# Buat file konfigurasi wg0.conf
cat > wg0.conf << EOF
[Interface]
Address = 10.9.0.1/24
ListenPort = 51820
PrivateKey = ${PRIV_KEY}

# Aturan NAT & Forwarding (Khusus NATVPS venet0)
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o venet0 -j MASQUERADE

# Koneksi ke MikroTik
[Peer]
PublicKey = ${MT_PUB_KEY}
AllowedIPs = 10.9.0.2/32, ${LOCAL_NET}
EOF

# Tambah rute jaringan lokal ke rc.local agar permanen
if ! grep -q "ip route add ${LOCAL_NET}" /etc/rc.local; then
    sed -i '/^exit 0/i ip route add '"${LOCAL_NET}"' via 10.9.0.2' /etc/rc.local
fi
chmod +x /etc/rc.local

# Terapkan rute sekarang
ip route add ${LOCAL_NET} via 10.9.0.2 || true

# Aktifkan layanan
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# Tampilkan informasi penting
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}>>> INSTALASI SELESAI! DATA PENTING:${NC}"
echo -e "Kunci Publik Server VPS : ${PUB_KEY}"
echo -e "IP Server VPN            : 10.9.0.1"
echo -e "Port Luar VPS            : ${EXT_PORT} -> 51820 (UDP)"
echo -e "Jaringan Lokal Diteruskan: ${LOCAL_NET}"
echo -e "${GREEN}==============================================${NC}"
echo -e "Jalankan perintah 'wg show' untuk cek status koneksi."