# ==============================================
# Konfigurasi MikroTik WireGuard Client
# Untuk koneksi ke NATVPS
# ==============================================

:local VPS_PUB_KEY "ISI_KUNCI_PUBLIK_VPS_DISINI"
:local VPS_IP "ISI_IP_PUBLIK_NATVPS_DISINI"
:local VPS_PORT "ISI_PORT_FORWARDING_DISINI"
:local LOCAL_NET "192.168.88.0/24"

# 1. Buat antarmuka WireGuard
/interface wireguard
add name=wg-to-natvps generate-private-key=yes

# Ambil kunci privat yang baru dibuat (simpan untuk catatan)
:local MT_PRIV_KEY [/interface wireguard get wg-to-natvps private-key]
:local MT_PUB_KEY [/interface wireguard get wg-to-natvps public-key]

:put ">>> Kunci Privat MikroTik: $MT_PRIV_KEY"
:put ">>> Kunci Publik MikroTik: $MT_PUB_KEY"

# 2. Tambah peer (server NATVPS)
/interface wireguard peers
add interface=wg-to-natvps \
    public-key="$VPS_PUB_KEY" \
    endpoint-address="$VPS_IP" \
    endpoint-port="$VPS_PORT" \
    allowed-address=10.9.0.0/24 \
    persistent-keepalive=25

# 3. Berikan IP ke antarmuka VPN
/ip address
add address=10.9.0.2/24 interface=wg-to-natvps network=10.9.0.0 comment="WireGuard to NATVPS"

# 4. Aktifkan penerusan paket
/ip settings set ip-forward=yes

# 5. NAT agar perangkat lokal bisa akses lewat VPN
/ip firewall nat
add chain=srcnat action=masquerade src-address="$LOCAL_NET" out-interface=wg-to-natvps comment="NAT WireGuard"

# 6. Izinkan trafik di Firewall
/ip firewall filter
add chain=forward action=accept in-interface=wg-to-natvps
add chain=forward action=accept out-interface=wg-to-natvps

:put ">>> Konfigurasi SELESAI. Cek status dengan /interface wireguard print"