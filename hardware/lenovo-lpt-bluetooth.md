### Title

MediaTek Bluetooth (`btusb`/`btmtk`) controller drops LE handle and resets under idle: `ACL packet for unknown connection handle 3837` with Logitech MX Keys Mini

---

### Environment

* **OS:** Fedora Linux 44
* **Kernel:** `7.2.11-200.fc44.x86_64`
* **Controller:** MediaTek Bluetooth Controller (`hci0`, USB interface `btusb`/`btmtk`, HW/SW Version: `0x008a008a`, Firmware Build: `20260724143815`)
* **Peripherals:**
* Logitech MX Keys Mini (BLE HID, `046D:B369`, MAC `D0:45:9D:4A:78:5C`)
* ASUS MD200 Mouse (BLE HID, `0B05:1A26`)



---

### Problem Description

When pairing a Logitech MX Keys Mini keyboard over native Bluetooth Low Energy (BLE), the device repeatedly disconnects or drops keystrokes after 40–80 seconds of idle time. The kernel log reports repeated `ACL packet for unknown connection handle 3837` errors followed by input device re-enumeration loops (`input319` -> `input329` -> `input401`...).

Under extended idle periods or during handle drops, the entire MediaTek controller firmware crashes and re-enumerates, resetting all active Bluetooth devices (including connected mice).

```text
[Tue Nov 10 18:03:56 2026] logitech-hidpp-device 0005:046D:B369.0070: input,hidraw3: BLUETOOTH HID v0.16 Keyboard [Logitech MX Keys Mini] on cc:5e:f8:2e:5f:8e
[Tue Nov 10 18:03:56 2026] logitech-hidpp-device 0005:046D:B369.0070: HID++ 4.5 device connected.
[Tue Nov 10 18:04:28 2026] Bluetooth: hci0: ACL packet for unknown connection handle 3837
[Tue Nov 10 18:07:00 2026] Bluetooth: hci0: ACL packet for unknown connection handle 512
[Tue Nov 10 18:07:00 2026] Bluetooth: hci0: HW/SW Version: 0x008a008a, Build Time: 20260724143815
[Tue Nov 10 18:07:00 2026] Bluetooth: hci0: Device setup in 147020 usecs
[Tue Nov 10 18:07:03 2026] hid-generic 0005:0B05:1A26.0071: input,hidraw2: BLUETOOTH HID v7.11 Mouse [ASUS MD200] on cc:5e:f8:2e:5f:8e
[Tue Nov 10 18:10:33 2026] hid-generic 0005:046D:B369.0072: input,hidraw3: BLUETOOTH HID v0.16 Keyboard [MX Keys Mini] on cc:5e:f8:2e:5f:8e

```

---

### Root Causes

1. **Driver Query Deadlock:** The `hid-logitech-hidpp` kernel driver continuously attempts GATT queries (battery/backlight status) over BLE. When the keyboard enters low-power sleep, unanswered HID++ queries cause the driver to tear down the device node and trigger continuous reconnection attempts.
2. **Aggressive BlueZ Supervision Timeout:** Default BlueZ connection parameters negotiate an aggressive timeout (`Timeout=210` / 2.1s) and high slave latency (`Latency=20`), leading the controller to drop the connection handle while the keyboard is sleeping.
3. **MediaTek Controller Firmware Desync:** When the keyboard wakes from sleep and flushes buffered ACL packets to the host, the MediaTek controller has already dropped the connection handle, emitting `ACL packet for unknown connection handle 3837` (`0x0EFD`). If the link falls out of sync, the controller firmware crashes and triggers a full hardware re-init.

---

### Mitigation / Workaround Steps

#### 1. Blacklist `hid_logitech_hidpp` to force standard `hid-generic`

Prevents the driver from initiating failing HID++ queries over BLE and stops device cycling:

```bash
echo "blacklist hid_logitech_hidpp" | sudo tee /etc/modprobe.d/blacklist-hidpp.conf

```

#### 2. Disable `btusb` autosuspend and ERTM

Mitigates host-side USB sleep transitions causing controller firmware resets:

```bash
sudo tee /etc/modprobe.d/btusb.conf << 'EOF'
options btusb enable_autosuspend=n reset=1
options bluetooth disable_ertm=1
EOF

```

#### 3. Extend BlueZ LE Connection Parameters

Adjust the connection parameters in `/var/lib/bluetooth/<CONTROLLER_MAC>/<DEVICE_MAC>/info` to prevent early handle drops:

```ini
[ConnectionParameters]
MinInterval=12
MaxInterval=24
Latency=4
Timeout=3200

```

#### 4. Active Keep-Alive Daemon via D-Bus

Because the keyboard's internal firmware powers down after 15–20 seconds of silence, a lightweight systemd daemon periodically reads the standard GATT Battery Characteristic (`UUID 0x2A19`, `service001b/char001c`) every 15 seconds. This generates non-intrusive bidirectional Link Layer packets that keep the hardware radio and the MediaTek connection handle active:

```python
# /usr/local/bin/ble-keepalive.py
import time, dbus

DEV_PATH = "/org/bluez/hci0/dev_D0_45_9D_4A_78_5C"
CHAR_PATH = DEV_PATH + "/service001b/char001c"

bus = dbus.SystemBus()
while True:
    try:
        char_obj = bus.get_object("org.bluez", CHAR_PATH)
        char_iface = dbus.Interface(char_obj, "org.bluez.GattCharacteristic1")
        char_iface.ReadValue(dbus.Dictionary({}, signature="sv"))
    except dbus.DBusException:
        pass
    time.sleep(15)

```
