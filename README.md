# QNAP QSW switch tools

QNAP QSW switches internally have a full blown Cisco-style management CLI hidden behind the dumbed down web interface.

## Physical console

Typical Cisco RJ45 pinout, 115200n1. The default CLI with the normal login doesn't let you do anything but enable SSH.

## CLI Backdoor

Log in with username `guest` and password `guest123` to get full access to the CLI. To enable privileged operations to make changes to switch configuration, use the `enable` command as usual. The password you will need can be generated with the `genpwd.py` script in this repo (you will need your switch serial number).

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

## Neutering the SSH backdoor

You'll probably want to replace the backdoor password with your own. Easiest is to just log in with the backdoor, and then do this:

```bash
chmod 600 /etc/shadow*
chmod 644 /etc/passwd* /etc/group /etc/pam.d/* /etc/pam.conf
sed -i 's,^root.*,root:x:0:0:root:/root:/bin/ash,' /etc/passwd
echo 'auth    required        pam_unix.so' > /etc/pam.d/sshd
passwd root
```

This disables the debug account (since it lacks a password) and enables the real root account with your choice of password.

For reference, these are the original contents of `/etc/pam.d/sshd`:

```
auth    optional        pam_unix.so nullok
auth    sufficient      pam_debugauth.so
auth    required        pam_deny.so
```

`pam_debugauth.so` implements the backdoor password.

## Other services

You can expose various services by commenting out stuff in `/etc/firewall.user` and then running `fw3`.

* Port 6023: ISS console (same as serial, with auth)
* Port 12345: Secret lua debug shell with low-level commands (no auth).
* Port 12346: Some kind of file transfer protocol, like FTP but inline (try `ls` and `get configToLoad.txt`). It's a virtual FS though.
* Port 31337: Like 12345 but without proper telnet/terminal mode (probably for scripting)
* Port 31338: Echo server?

Alternatively, use SSH forwarding (`ssh -L 6023:localhost:6023`) to tunnel the shell over SSH instead of just opening the ports.

## User management

The `admin` user can change the password for `guest` via the web API:

```bash
switch=192.168.98.16
b64pwd="$(echo -n YOURPASSWORD | base64)"
auth="$(curl -k https://$switch/api/v1/users/login -X POST -d "{\"username\": \"admin\", \"password\": \"$b64pwd\"}" | jq -r .result)"
curl -k https://$switch/api/v1/users -X PUT -H "authorization: Bearer $auth" -d '{"idx":"guest","data":{"Password": "NEWPASSWORD"}}'
```

There is no way to change the enable password, that is hardcoded. However, you can add a new user with privilege level 15 using the API too:

```bash
curl -k https://$switch/api/v1/users -X POST -H "authorization: Bearer $auth" -d '{"idx":"root","data":{"Password": "NEWPASSWORD", "Privilege": 15}}'
```

That gets you a `root` user which can log into the CLI and get all the commands without having to use `enable` with the backdoor password.

You can also use the `DELETE` verb to delete users (but `admin` and `guest` cannot be deleted).

The web UI seems to be limited to the `admin` user, but gets full privileges to the API with it. The CLI username `admin` is hardcoded to be downgraded to privilege 0 even though it's 15, that's why it only gets a crippled shell. Unfortunately, it's also the only user that gets to use the `username` config commands, so there is no way to manage users from the CLI.

If you've done all of the above, the switch should be reasonably secure (root SSH with your own password only, local CLI requires login with your own password as all users).
