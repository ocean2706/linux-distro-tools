sudo systemctl stop bluetooth && \
echo "[*] Waiting up to 5s for bluetoothd to release lock..." && \
timeout 5 bash -c 'while pgrep -x bluetoothd > /dev/null; do sleep 0.2; done' || echo "[!] Proceeding after timeout..." && \
echo "[*] Modifying ConnectionParameters..." && \
sudo sed -i '/^\[ConnectionParameters\]/,/^\[/ s/^MinInterval=.*/MinInterval=12/' /var/lib/bluetooth/CC:5E:F8:2E:5F:8E/D0:45:9D:4A:78:5C/info && \
sudo sed -i '/^\[ConnectionParameters\]/,/^\[/ s/^MaxInterval=.*/MaxInterval=24/' /var/lib/bluetooth/CC:5E:F8:2E:5F:8E/D0:45:9D:4A:78:5C/info && \
sudo sed -i '/^\[ConnectionParameters\]/,/^\[/ s/^Latency=.*/Latency=4/' /var/lib/bluetooth/CC:5E:F8:2E:5F:8E/D0:45:9D:4A:78:5C/info && \
sudo sed -i '/^\[ConnectionParameters\]/,/^\[/ s/^Timeout=.*/Timeout=600/' /var/lib/bluetooth/CC:5E:F8:2E:5F:8E/D0:45:9D:4A:78:5C/info && \
echo "[*] Starting bluetooth service..." && \
sudo systemctl start bluetooth && \
echo "[*] Current ConnectionParameters state:" && \
grep -A 5 "\[ConnectionParameters\]" /var/lib/bluetooth/CC:5E:F8:2E:5F:8E/D0:45:9D:4A:78:5C/info
