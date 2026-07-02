#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="zesinger"
REPO="ZeDART_ADSBDevice"
BRANCH="main"

BASE_PRIMARY="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/${BRANCH}"

DEVICE_SERVER="zedart-device-server.py"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
fail() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

download() {
    local name="$1"
    local dst="$2"

    info "Downloading ${name}..."

    if curl -fsSL "${BASE_PRIMARY}/${name}" -o "$dst"; then
        ok "${name} downloaded from primary source."
        return
    fi
    fail "Unable to download ${name}."
}

if [ "$(id -u)" -ne 0 ]; then
    fail "Please run as root: curl ... | sudo bash"
fi

echo
echo "========================================="
echo " ZeDART ADS-B Device Installer"
echo "========================================="
echo

info "Installing base packages..."
apt-get update
apt-get install -y curl wget python3 network-manager
ok "Base packages installed."

info "Enabling SSH..."
systemctl enable ssh || true
systemctl start ssh || true
ok "SSH enabled."

info "Installing readsb..."
if systemctl list-unit-files | grep -q "^readsb.service"; then
    ok "readsb already installed."
else
    bash -c "$(curl -L https://github.com/wiedehopf/adsb-scripts/raw/master/readsb-install.sh)"
    ok "readsb installed."
fi

info "Installing tar1090..."
if [ -d /usr/local/share/tar1090 ] || [ -d /var/www/html/tar1090 ]; then
    ok "tar1090 already installed."
else
    bash -c "$(wget -nv -O - https://github.com/wiedehopf/tar1090/raw/master/install.sh)"
    ok "tar1090 installed."
fi

info "Configuring Ethernet eth0 as 192.168.50.1/24..."

CONN="$(nmcli -t -f NAME,DEVICE connection show | awk -F: '$2=="eth0"{print $1}' | head -n 1)"

if [ -z "$CONN" ]; then
    info "No eth0 connection found, creating ZeDART-ETH."
    nmcli connection add type ethernet ifname eth0 con-name ZeDART-ETH
    CONN="ZeDART-ETH"
fi

nmcli connection modify "$CONN" \
    ipv4.method manual \
    ipv4.addresses 192.168.50.1/24 \
    ipv4.gateway "" \
    ipv4.dns "" \
    ipv6.method disabled \
    connection.autoconnect yes

nmcli connection up "$CONN" || true
ok "Ethernet configured."

info "Installing ZeDART device server..."
download "$DEVICE_SERVER" /opt/zedart-device-server.py
chmod +x /opt/zedart-device-server.py
ok "Device server installed."

info "Creating systemd service..."

cat > /etc/systemd/system/zedart-device-server.service <<'EOF'
[Unit]
Description=ZeDART Device Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/zedart-device-server.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zedart-device-server
systemctl restart zedart-device-server

if systemctl is-active --quiet zedart-device-server; then
    ok "ZeDART device server is running."
else
    fail "ZeDART device server failed to start."
fi

info "Checking readsb..."
systemctl enable readsb || true
systemctl restart readsb || true

if systemctl is-active --quiet readsb; then
    ok "readsb is running."
else
    info "readsb is not running yet. Check SDR dongle and configuration."
fi

echo
echo "========================================="
echo " ZeDART ADS-B Device installation done"
echo "========================================="
echo "Ethernet IP : 192.168.50.1"
echo "Device API  : http://192.168.50.1:8765"
echo "tar1090     : http://192.168.50.1/tar1090/"
echo "SSH         : enabled"
echo
echo "Recommended final step:"
echo "sudo reboot"
echo
