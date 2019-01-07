# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Run DragonFly BSD in illumos KVM (nested)
#   https://github.com/joyent/illumos-kvm-cmd
#   https://omnios.omniti.com/wiki.php/VirtualMachinesKVM
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'deploy_kvm';

sub run {
    select_console 'user-console';

    # Get the image
    my $image = 'dfly-x86_64-5.4.1_REL.iso';
    assert_script_run("wget http://ftp.halifax.rwth-aachen.de/dragonflybsd/iso-images/${image}.bz2", 300);
    assert_script_run "bunzip2 -v ${image}.bz2";

    deploy_kvm;

    my $macaddr = '90:b8:d0:c0:ff:ee';
    script_sudo(
        "qemu-kvm -enable-kvm -vga std -drive file=$image,media=cdrom,if=ide "
          . "-vnc 0.0.0.0:0 -no-hpet -net nic,vlan=0,name=net0,model=virtio,macaddr=$macaddr "
          . "-net vnic,vlan=0,name=net0,ifname=vnic0,macaddr=$macaddr "
          . "-boot d -m 512 -serial /dev/$testapi::serialdev 2>&1 | tee qemu_kvm.log | tee /dev/$testapi::serialdev &",
        0
    );
    wait_serial('Start bios') || die 'Alpine did not boot';
    select_console 'vnc';
    console('vnc')->disable_vnc_stalls;

    assert_screen('dragonfly-bootloader');
    send_key 'esc';
    assert_screen('dragonfly-okprompt');
    type_string "boot\n";
    assert_screen('dragonfly-uname',  90);
    assert_screen('dragonfly-banner', 90);
    assert_screen('dragonfly-login');
    type_string "root\n";
    assert_screen('dragonfly-prompt');
    # Now we can use serial line
    my $host_serialdev = $testapi::serialdev;
    $testapi::serialdev = 'ttyd0';    # COM1
    assert_script_run 'uname -a';
    assert_script_run 'sysctl machdep.spectre_mitigation';
    assert_script_run 'sysctl machdep.meltdown_mitigation';
    type_string "exit\n";
    assert_screen('dragonfly-login');
    type_string "installer\n";
    send_key_until_needlematch('dragonfly-installer', 'f10', 10, 5);
    $testapi::serialdev = $host_serialdev;

    select_console 'user-console';
    script_output('kvmstat 1 5 | grep -v "pid vcpu"') || die "'kvmstat' did not produce statistics";

    select_console 'vnc';

    send_key_until_needlematch('dragonfly-installer-reboot', 'tab');
    send_key 'ret';
    assert_screen('dragonfly-installer-reboot-question');
    send_key 'ret';
    assert_screen('dragonfly-system-halted', 90);
    select_console 'user-console';
    assert_script_sudo 'kill `pgrep qemu-kvm`';
    upload_logs('qemu_kvm.log');

    assert_script_sudo('modunload -i $(modinfo | grep kvm | awk "{ print $1 }")');
    assert_script_sudo('modinfo | grep kvm && false || true');
    console('vnc')->reset;    # To make sure we activate VNC of new VM on reconnect
}

1;

# vim: set sw=4 et:
