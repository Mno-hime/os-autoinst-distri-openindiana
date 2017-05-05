# OpenIndiana's openQA tests
#
# Copyright © 2016 SUSE LLC
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Xen bootloader
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use warnings;
use testapi;
use utils;

use File::Basename;

sub run() {
    my $vmm_type = get_required_var('VIRSH_VMM_TYPE');

    my $svirt = select_console('svirt');
    my $name  = $svirt->name;

    my $xenconsole = 'hvc0';

    if ($vmm_type eq 'linux') {
        $svirt->change_domain_element(os => initrd => "/var/lib/libvirt/images/$name.initrd");
        # <os><kernel>...</kernel></os> defaults to grub.xen, we need to remove
        # content first if booting kernel diretly
        $svirt->change_domain_element(os => kernel => undef);
        $svirt->change_domain_element(os => kernel => "/var/lib/libvirt/images/$name.kernel");
    }
    if ($vmm_type eq 'hvm') {
        $svirt->change_domain_element(features => apic => undef);
    }

    $svirt->change_domain_element(devices => video => model => {type => get_var('VGA', 'cirrus')});

    my $size_i = get_var('HDDSIZEGB', '24');
    $svirt->add_disk(
        {
            size      => $size_i . 'G',
            create    => 1,
            dev_id    => 'a',
            bootorder => 1
        });

    # In JeOS and netinstall we don't have ISO media, for the rest we have to attach it.
    my $isofile = get_required_var('ISO');
    $svirt->add_disk(
        {
            cdrom     => 1,
            file      => $isofile,
            dev_id    => 'b',
            bootorder => 2
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

    # We can use bridge or network as a base for network interface. Network named 'default'
    # happens to be omnipresent on workstations, bridges (br0, ...) on servers. If both 'default'
    # network and bridge are defined and active, bridge should be prefered as 'default' network
    # does not work.
    if (my $bridges = $svirt->get_cmd_output("virsh iface-list --all | grep -w active | awk '{ print \$1 }' | tail -n1 | tr -d '\\n'")) {
        $ifacecfg{type} = 'bridge';
        $ifacecfg{source} = {bridge => $bridges};
    }
    elsif (my $networks = $svirt->get_cmd_output("virsh net-list --all | grep -w active | awk '{ print \$1 }' | tail -n1 | tr -d '\\n'")) {
        $ifacecfg{type} = 'network';
        $ifacecfg{source} = {network => $networks};
    }

    # Dosable network interface as it panics illumos kernel
    #$svirt->add_interface(\%ifacecfg);

    $svirt->define_and_start;

    # connects to a guest VNC session on Xen HVM,
    # illumos PV won't set framebuffer.
    select_console('sut') if ($vmm_type eq 'hvm');
}

1;
