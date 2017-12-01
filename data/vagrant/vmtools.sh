#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ virtualbox ]]; then

    echo "==> Installing VirtualBox guest additions"

    echo "mail=\ninstance=overwrite\npartial=quit" > /tmp/noask.admin
    echo "runlevel=nocheck\nidepend=quit\nrdepend=quit" >> /tmp/noask.admin
    echo "space=quit\nsetuid=nocheck\nconflict=nocheck" >> /tmp/noask.admin
    echo "action=nocheck\nbasedir=default" >> /tmp/noask.admin

    LOFIDEV=$(lofiadm -a VBoxGuestAdditions.iso)
    mount -F hsfs ${LOFIDEV} /mnt
    pkgadd -a /tmp/noask.admin -G -d /mnt/VBoxSolarisAdditions.pkg all
    umount /mnt

    lofiadm -d ${LOFIDEV}

	rm -f ${HOME}/VBoxGuestAdditions.iso
    rm -f ${HOME}/.vbox_version
else
	echo '==> Skipping vagrant configuration for this platform'
fi
