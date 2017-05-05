# OpenIndiana's openQA tests
#
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: VirtualBox bootloader
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use warnings;
use testapi;

sub run() {
    my $svirt = select_console('svirt');
    my $name  = $svirt->name;

    type_string "VBoxManage controlvm $name poweroff\n";
    sleep 2;
    type_string "VBoxManage unregistervm $name --delete\n";
    sleep 2;
    type_string "VBoxManage setproperty vrdeextpack VNC\n";
    sleep 2;
    type_string "VBoxManage createvm --name $name --register\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --ostype Solaris11_64\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --memory " . get_var('QEMURAM') . "\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --boot1 disk\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --boot2 dvd\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --vrdeproperty VNCPassword=" . $testapi::password . "\n";
    sleep 2;
    my $instance = 5900 + get_var('VIRSH_INSTANCE');
    type_string "VBoxManage modifyvm $name --vrde on --vrdeaddress '' --vrdeport $instance\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --vram 4 --accelerate3d off --audio pulse --audiocontroller ac97\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --nic1 nat --nictype1 virtio --cableconnected1 on\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --mouse usbtablet\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --uart1 0x3F8\n";
    sleep 2;
    type_string "VBoxManage modifyvm $name --uartmode1 tcpserver " . get_var('VIRTUALBOX_SERIAL_PORT') . "\n";
    sleep 2;
    type_string "VBoxManage createhd --filename $name --size " . 1024 * get_var('HDDSIZEGB') . "\n";
    sleep 2;
    type_string "VBoxManage storagectl $name --name SATA --add sata --controller IntelAhci --bootable on\n";
    sleep 2;
    type_string "VBoxManage storagectl $name --name IDE --add ide --controller PIIX4 --bootable on\n";
    sleep 2;
    type_string "VBoxManage storageattach $name --storagectl SATA --port 0 --device 0 --type hdd --medium $name.vdi\n";
    sleep 2;
    type_string "VBoxManage storageattach $name --storagectl IDE --port 0 --device 0 --type dvddrive --medium " . get_var('ISO') . "\n";
    sleep 2;
    type_string "VBoxManage startvm $name --type headless\n";
    sleep 5;
    type_string "netstat -tulpn | grep 8008\n";

    # Get serial port
    $svirt->attach_to_running({name => $name});

    # connects to a guest VNC session
    select_console('sut');
}

1;
