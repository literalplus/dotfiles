# custom wifi hotspot that routes through to wifi client of laptop

## method 0 that didn't really work

/etc/NetworkManager/system-connections/CustomHotspot.nmconnection

```
[connection]
id=CustomHotspot
uuid=aa3efe23-277a-44e8-b4fd-c690852923e6
type=wifi
autoconnect=false
interface-name=wlan-ap

[wifi]
mode=ap
ssid=kafka keksausstecher

[wifi-security]
group=ccmp;
key-mgmt=wpa-psk
pairwise=ccmp;
proto=rsn;
psk=XXX

[ipv4]
address1=192.168.167.1/24,192.168.167.1
dns=8.8.8.8;
method=manual

[ipv6]
addr-gen-mode=default
method=auto

[proxy]

```

## method 1 that worked once, but isn't reproducible

https://github.com/lakinduakash/linux-wifi-hotspot

```
sudo iw dev wlp0s20f3 interface add wlan-ap type __ap
yay -Sy linux-wifi-hotspot # don't use the gui, it doesn't allow to disable dns server (which conflicts with systemd-resolved running on hte same port)
pkexec --user root create_ap wlan-ap wlp0s20f3 'kafka keksausstecher 2' 'XXXX' --no-dns --freq-band 2.4 --no-dnsmasq
```

device settings on phone:
  ip 192.168.12.2
  gw 192.168.12.1

sudo sysctl -w net.ipv4.ip_forward=1

## method 2 with two virtual interfaces



```
➜  ~ cat /etc/create_ap.conf 
CHANNEL=default
GATEWAY=192.168.12.1
WPA_VERSION=2
ETC_HOSTS=0
DHCP_DNS=gateway
NO_DNS=1
NO_DNSMASQ=1
HIDDEN=0
MAC_FILTER=0
MAC_FILTER_ACCEPT=/etc/hostapd/hostapd.accept
ISOLATE_CLIENTS=0
SHARE_METHOD=nat
IEEE80211N=0
IEEE80211AC=0
IEEE80211AX=0
HT_CAPAB=[HT40+]
VHT_CAPAB=
DRIVER=nl80211
NO_VIRT=0
COUNTRY=
FREQ_BAND=2.4
NEW_MACADDR=
DAEMONIZE=0
DAEMON_PIDFILE=
DAEMON_LOGFILE=/dev/null
DNS_LOGFILE=
NO_HAVEGED=0
WIFI_IFACE=wlan-ap
INTERNET_IFACE=wlp0s20f3
SSID=kafka keksausstecher 2
PASSPHRASE=XXX
USE_PSK=0
ADDN_HOSTS=
$ sudo iw dev wlp0s20f3 interface add wlan-ap type __ap
$ sudo systemctl start create_ap
$ sudo ip link 
$ nmcli r wifi off #  ? needed ? 
$ rfkill unblock wlan
$ sudo ip link set wlan-ap up  
$ sudo sysctl -w net.ipv4.ip_forward=1
```
