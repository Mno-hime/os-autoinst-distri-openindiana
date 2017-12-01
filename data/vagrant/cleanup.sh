#!/bin/bash -eux

echo "==> Dosable root login via SSH"
sed -i -e 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

echo "==> Cleaning up SSH host keys"
# If the key doesn't exist, we shouldn't end with
# non-zero return code, as packer will fail.
rm -f /etc/ssh/ssh_host_ecdsa_key{,.pub}
rm -f /etc/ssh/ssh_host_dsa_key{,.pub}
rm -f /etc/ssh/ssh_host_rsa_key{,.pub}
rm -f /etc/ssh/ssh_host_ed25519_key{,.pub}

echo "==> Emptying log files from /var/adm"
find /var/{adm,log} -type f -exec cp /dev/null {} \;
