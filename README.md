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
