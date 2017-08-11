#!/bin/bash -eux

# From https://github.com/boxcutter/debian/blob/master/script/cleanup.sh

CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
sleep "${CLEANUP_PAUSE}"

# Unique SSH keys will be generated on first boot
echo "==> Removing SSH server keys"
rm -f /etc/ssh/*_key*

# SSH Config
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Unique machine ID will be generated on first boot
echo "==> Removing machine ID"
rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
touch /etc/machine-id

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up leftover dhcp leases"
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Setup minifridge-firstboot to initialize ssh keys
echo "==> Creating /etc/rc.local that runs on first boot"
cat <<EOF >/etc/rc.local
#!/bin/sh
# First boot to initialize things that need initializing.
# rc.local can be deleted after first successful boot (but it
# can't safely delete itself).
if [ -e /etc/minifridge-firstboot ]; then
	dpkg-reconfigure --frontend=noninteractive openssh-server
	# never need to run again
	rm -f /etc/minifridge-firstboot
fi
EOF
chmod +x /etc/rc.local
touch /etc/minifridge-firstboot

# Cleanup apt cache
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

echo "==> Installed packages"
dpkg --get-selections | grep -v deinstall

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history

# Clean up log files
echo "==> Purging log files"
find /var/log -type f -delete
