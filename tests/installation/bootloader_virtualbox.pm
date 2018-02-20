# OpenIndiana's openQA tests
#
# Copyright © 2017 SUSE LLC
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: VirtualBox bootloader
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'basetest';
use strict;
use warnings;
use testapi;
use File::Basename 'basename';

sub vbox_cmd {
    my ($cmd, $args) = @_;
    $args->{can_fail} ||= 0;
    my $ret       = console('svirt')->run_cmd($cmd);
    my $cmd_strip = $cmd;
    diag "VBoxManage command '$cmd_strip' returned: $ret";
    die "\n\nVBoxManage command:\n\n\t$cmd_strip\n\nfailed" unless ($args->{can_fail} || !$ret);
    return $ret;
}

sub copy_medium_to_cache {
    my ($medium)      = @_;
    my $cachedir      = get_required_var('CACHEDIRECTORY');
    my $cached_medium = `find $cachedir -name $medium -type f`;
    diag "Cached medium: $cached_medium";
    return $cached_medium if $cached_medium;
    my $assetdir    = get_required_var('ASSETDIR');
    my $medium_path = `find /var/lib/libvirt/images/ $assetdir -name $medium | tail -n1 | tr -d '\n'`;
    diag "Medium path: ${medium_path}; downloading...";
    die "Can't find $medium in defined paths" unless $medium_path;
    `cp -vf $medium_path $cachedir` || die "Can't copy $medium_path to $cachedir";
    return "${cachedir}/${medium}";
}

sub run() {
    my $svirt = select_console('svirt');
    my $name  = $svirt->name;

    my $homedir = '/var/lib/libvirt/images';
    vbox_cmd("VBoxManage setproperty machinefolder '${homedir}'");
    vbox_cmd("if VBoxManage list runningvms | grep -w $name; then VBoxManage controlvm $name poweroff; fi");
    # Files attached to a VM from previous run with the same VIRSH_INSTANCE should not be
    # removed via `--delete` option to `unregistervm` command because it removes link in
    # pool/#/ to the HDD image. We remove the files per scenario later, see `closemedium`.
    vbox_cmd("if VBoxManage list vms | grep -w $name; then VBoxManage unregistervm $name; fi");
    # Remove leftover VM machine folder, and disk(s)
    vbox_cmd("rm -rfv ${homedir}/${name}");

    vbox_cmd("VBoxManage setproperty vrdeextpack VNC");
    vbox_cmd("VBoxManage createvm --name $name --register");
    my $instance       = 5900 + get_var('VIRSH_INSTANCE');
    my $qemuram        = get_var('QEMURAM');
    my $qemucpus       = get_var('QEMUCPUS');
    my $nictype1       = get_var('VBOXNICTYPE', '82545EM');
    my $vb_serial_port = get_var('VIRTUALBOX_SERIAL_PORT');
    my $storage        = uc(get_var('VBOXHDDTYPE') || 'SATA');
    my $storage_2nd    = uc(get_var('VBOXHDDTYPE2') || $storage);
    my $controller     = get_var('VBOXHDDMODEL') || 'IntelAhci';
    my $controller_2nd = get_var('VBOXHDDMODEL2') || $controller;
    # Empty 'usbtype' is 'OHCI'
    my $usbtype = get_var('VBOXUSBTYPE', '');
    my $audio = '--audiocontroller ac97 --audio ' . (check_var('FLAVOR', 'Live') ? 'pulse' : 'none');
    my $iso = copy_medium_to_cache(basename get_var('ISO'));
    vbox_cmd("VBoxManage modifyvm $name --ostype Solaris11_64 --boot1 disk --boot2 dvd "
          . "--cpus $qemucpus --longmode on "
          . "--memory $qemuram --pagefusion on "
          . "--vrde on --vrdeproperty VNCPassword=$testapi::password --vrdeaddress '' --vrdeport $instance "
          . "--vram 4 $audio "
          . "--mouse usbtablet --usb$usbtype on "
          . "--nic1 nat --nictype1 $nictype1 --cableconnected1 on "
          . "--ioapic on --apic on --x2apic off --acpi on --biosapic=apic --rtcuseutc on --paravirtprovider kvm "
          . "--chipset piix3 --uart1 0x3F8 4 --uartmode1 tcpserver $vb_serial_port ");
    vbox_cmd("VBoxManage storagectl $name --name $storage --add " . lc $storage . " --controller $controller --bootable on --hostiocache on");
    if ($storage ne $storage_2nd) {
        vbox_cmd("VBoxManage storagectl $name --name $storage_2nd --add " . lc $storage_2nd . " --controller $controller_2nd --bootable on --hostiocache on");
    }
    vbox_cmd("VBoxManage storageattach $name --storagectl $storage --port 0 --device 0 --type dvddrive --medium $iso");
    my $numdisks = get_var('NUMDISKS');
    for my $port (1 .. $numdisks) {
        my $hddname = "${homedir}/${name}_${port}";
        vbox_cmd("VBoxManage closemedium disk $hddname.vdi --delete", {can_fail => 1});
        vbox_cmd("rm -fv $hddname.vdi");
        my $diffparent = '';
        my $hddsize = '--size ' . 1024 * get_var('HDDSIZEGB', 10);
        if (my $hddx = get_var("HDD_$port")) {
            $diffparent = "--diffparent $hddx";
            $hddsize    = '';
            my $basename_hddx = basename($hddx);
            vbox_cmd("VBoxManage closemedium disk $homedir/$basename_hddx",                    {can_fail => 1});
            vbox_cmd("VBoxManage closemedium disk /var/lib/openqa/libvirtroot/$basename_hddx", {can_fail => 1});
            vbox_cmd("VBoxManage closemedium disk $hddx",                                      {can_fail => 1});
        }
        vbox_cmd("VBoxManage createmedium disk $diffparent --filename $hddname $hddsize");
        vbox_cmd("VBoxManage storageattach $name --storagectl $storage_2nd --port $port --device 0 "
              . "--type hdd --medium $hddname.vdi --nonrotational on --discard on");
    }
    vbox_cmd("VBoxManage startvm $name --type headless");

    # Connect to serial port
    $svirt->attach_to_running({name => $name, stop_vm => 1});

    # connects to a guest VNC session
    select_console('sut');
}

sub test_flags() {
    return {fatal => 1};
}

1;
