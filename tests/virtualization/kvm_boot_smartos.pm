# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Run SmartOS in illumos KVM (nested)
#   https://github.com/joyent/illumos-kvm-cmd
#   https://omnios.omniti.com/wiki.php/VirtualMachinesKVM
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'deploy_kvm';

sub run() {
    select_console 'user-console';

    my $image = 'smartos-20170330T015208Z.iso';
    deploy_kvm($image);

    my $macaddr = '90:b8:d0:c0:ff:ee';
    script_sudo(
        "qemu-kvm -enable-kvm -vga std -drive file=$image,media=cdrom,if=ide "
          . "-vnc 0.0.0.0:0 -no-hpet -net nic,vlan=0,name=net0,model=virtio,macaddr=$macaddr "
          . "-net vnic,vlan=0,name=net0,ifname=vnic0,macaddr=$macaddr "
          . "-boot d -m 1024 -serial /dev/$testapi::serialdev 2>&1 | tee qemu_kvm.log",
        0
    );
    sleep 10;
    select_console 'vnc';

    assert_screen('smartos-bootloader');
    send_key 'ret';
    assert_screen('smartos-uname',     90);
    assert_screen('smartos-installer', 90);
    send_key 'ctrl-c';
    assert_screen('smartos-prompt');

    select_console 'root-console';
    my $kvmstat_output = script_output('kvmstat 1 5 | grep -v "pid vcpu"');
    die "'kvmstat' did not produce statistics" unless $kvmstat_output;

    select_console 'vnc';

    assert_script_run 'uname -a';
    type_string "poweroff\n";
    if (check_screen('illumos-press-any-key-to-reboot')) {
        record_soft_failure 'illumos will not poweroff under QEMU';
        select_console 'user-console';
        send_key 'ctrl-c';
        sleep 3;
    }
    else {
        select_console 'user-console';
    }
    upload_logs('qemu_kvm.log');

    assert_script_sudo('modunload -i $(modinfo | grep kvm | awk "{ print $1 }")');
    assert_script_sudo('modinfo | grep kvm && false || true');
    reset_console('vnc');    # To make sure we activate VNC of new VM on reconnect
}

1;

# vim: set sw=4 et:
