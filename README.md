# QNAP QSW switch tools

QNAP QSW switches internally have a full blown Cisco-style management CLI hidden behind the dumbed down web interface.

## Physical console

Typical Cisco RJ45 pinout, 115200n1. The default CLI with the normal login doesn't let you do anything.

## CLI Backdoor

Log in with username `guest` and `guest123` to get full access to the CLI. To enable privileged operations to make changes to switch configuration, use the `enable` command as usual. The password you will need can be generated with the `genpwd.py` script in this repo (you will need your switch serial number).

The `guest:guest123` login doesn't seem to work in the web interface, thankfully.

However, if you enable ssh, logging in as the `debug` user with the same enable password as above will give you a root shell.

## Decrypting firmware

QNAP firmware images are plain tarballs, but every file contained within is encrypted. Use `decfile.sh` to decrypt them.

## Using a management VLAN other than 1

The CLI allows you to set IPs on more than one VLAN, but the firmware stupidly only sets the IP on the Linux TAP interface for interface "vlan1":

```c
iVar1 = strcmp(local_10,"vlan1");
if (iVar1 == 0) {
    cpsstap_update_ip(*param_1,param_1[1]);
}
```

... but you can cheat. Just leave vlan 1 unused, but set the IP you want on it. Then create an IP interface for the VLAN you actually want:

```
interface vlan 1
ip address  192.168.98.16 255.255.255.0
no shutdown
!
interface vlan 98
no shutdown
!
ip route 0.0.0.0  0.0.0.0 192.168.98.1
domain name-server ipv4 192.168.98.1
```

As long as the interface on the VLAN you want exists and is `no shutdown`, its traffic will go to the TAP interface that stuff is listening on, which will then get its IP from VLAN 1's IP.

Note: With this trick, ping won't work, since that is handled at a lower layer and the IP does not match there.

