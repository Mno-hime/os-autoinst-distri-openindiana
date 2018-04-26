# OpenIndiana's openQA tests
#
# Copyright © 2016 SUSE LLC
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Xen bootloader
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'basetest';
use strict;
use warnings;
use testapi;
use utils;

use File::Basename;

sub run {
    my $vmm_type   = get_required_var('VIRSH_VMM_TYPE');
    my $vmm_family = get_required_var('VIRSH_VMM_FAMILY');

    my $svirt = select_console('svirt');
    my $name  = $svirt->name;

    if ($vmm_type eq 'linux') {
        $svirt->change_domain_element(os => initrd => "/var/lib/openqa/share/factory/tmp/$name.initrd");
        # <os><kernel>...</kernel></os> defaults to grub.xen, we need to remove
        # content first if booting kernel diretly
        $svirt->change_domain_element(os => kernel => undef);
        $svirt->change_domain_element(os => kernel => "/var/lib/openqa/share/factory/tmp/$name.kernel");
    }

    set_var('QEMUVGA', 'cirrus') unless get_var('QEMUVGA');
    $svirt->change_domain_element(devices => video => model => {type => get_var('QEMUVGA')});

    my $size_i = get_var('HDDSIZEGB', '24');
    my $numdisks = get_var('NUMDISKS');
    for my $n (1 .. $numdisks) {
        $svirt->add_disk(
            {
                size      => $size_i . 'G',
                create    => 1,
                dev_id    => chr(ord('a') + $n - 1),
                bootorder => $n
            });
    }

    my $isofile = get_required_var('ISO');
    $svirt->add_disk(
        {
            cdrom     => 1,
            file      => $isofile,
            dev_id    => chr(ord('a') + $numdisks),
            bootorder => $numdisks + 1
        });

    # We need to use 'tablet' as a pointer device, i.e. a device
    # with absolute axis. That needs to be explicitely configured
    # on KVM and Xen HVM only. VMware and Xen PV add pointer
    # device with absolute axis by default.
    if ($vmm_type eq 'hvm') {
        $svirt->add_input({type => 'tablet',   bus => 'usb'});
        $svirt->add_input({type => 'keyboard', bus => 'ps2'});
    }

    my $console_target_type;
    if ($vmm_type eq 'linux') {
        $console_target_type = 'xen';
    }
    else {
        $console_target_type = 'serial';
    }
    my $pty_dev_type;
    $pty_dev_type = 'pty';
    $svirt->add_pty(
        {
            pty_dev      => 'console',
            pty_dev_type => $pty_dev_type,
            target_type  => $console_target_type,
            target_port  => '0'
        });
    if ($vmm_type eq 'hvm') {
        $svirt->add_pty(
            {
                pty_dev      => 'serial',
                pty_dev_type => $pty_dev_type,
                target_port  => '0'
            });
    }

    $svirt->add_vnc({port => get_var('VIRSH_INSTANCE', 1) + 5900});

    my %ifacecfg = ();

    # VMs should be specified with known-to-work network interface.
    # Xen PV and Hyper-V use streams.
    my $iface_model;
    if ($vmm_type eq 'hvm') {
        $iface_model = 'netfront';
    }

    if ($iface_model) {
        $ifacecfg{model} = {type => $iface_model};
    }

    my $virsh_vmm_iface_type = get_var('VIRSH_VMM_IFACE_TYPE', 'network');
    $ifacecfg{type} = $virsh_vmm_iface_type;
    $ifacecfg{source} = {$virsh_vmm_iface_type => get_var('VIRSH_VMM_IFACE_TYPE', 'default')};

    $svirt->add_interface(\%ifacecfg);

    $svirt->define_and_start;

    # Connects to a guest VNC session on Xen HVM, illumos PV won't set console framebuffer.
    select_console('sut') if $vmm_type eq 'hvm';
}

sub test_flags {
    return {fatal => 1};
}

1;
