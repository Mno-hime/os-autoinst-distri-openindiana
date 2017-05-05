# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Run Alpine Linux in illumos KVM (nested)
#   https://github.com/joyent/illumos-kvm-cmd
#   https://omnios.omniti.com/wiki.php/VirtualMachinesKVM
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'deploy_kvm';

sub run() {
    select_console 'user-console';

    my $image = 'alpine-virt-3.5.2-x86_64.iso';
    deploy_kvm($image);

    my $macaddr = '90:b8:d0:c0:ff:ee';
    script_sudo(
        "qemu-kvm -enable-kvm -vga std -drive file=$image,media=cdrom,if=ide "
          . "-vnc 0.0.0.0:0 -no-hpet -net nic,vlan=0,name=net0,model=virtio,macaddr=$macaddr "
          . "-net vnic,vlan=0,name=net0,ifname=vnic0,macaddr=$macaddr "
          . "-boot d -m 128 -serial /dev/$testapi::serialdev 2>&1 | tee qemu_kvm.log",
        0
    );
    select_console 'vnc';

    for (1 .. 5) { send_key 'esc'; sleep 1; }    # Make sure we stop the isolinux bootloader
    assert_screen('boot-alpine');
    send_key 'tab';
    type_string "virtgrsec noapic\n";
    assert_screen('welcome-to-alpine');

    select_console 'root-console';
    my $kvmstat_output = script_output('kvmstat 1 5 | grep -v "pid vcpu"');
    die "'kvmstat' did not produce statistics" unless $kvmstat_output;

    select_console 'vnc';
    type_string "root\n";
    assert_screen('alpine-prompt');

    my $host_serialdev = $testapi::serialdev;
    $testapi::serialdev = 'ttyS0';
    # Now we can use serial line
    assert_script_run 'cat /proc/cmdline';
    assert_script_run 'ifconfig eth0 up';
    assert_script_run 'udhcpc';
    assert_script_run 'ip addr';
    assert_script_run 'wget google.com';
    assert_script_run 'poweroff';
    select_console 'user-console';

    $testapi::serialdev = $host_serialdev;
    wait_serial 'Power down' || die 'Guest did not shutdown properly';
    upload_logs('qemu_kvm.log');

    assert_script_sudo('modunload -i $(modinfo | grep kvm | awk "{ print $1 }")');
    assert_script_sudo('modinfo | grep kvm && false || true');
    reset_console('vnc');    # To make sure we activate VNC of new VM on reconnect
}

1;

# vim: set sw=4 et:
