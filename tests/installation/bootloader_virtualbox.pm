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

use base 'basetest';
use strict;
use warnings;
use testapi;

sub run() {
    my $svirt = select_console('svirt');
    my $name  = $svirt->name;

    my $vbm     = 'VBoxManage ';
    my $homedir = get_required_var('CACHEDIRECTORY');

    $svirt->run_cmd("$vbm setproperty machinefolder '${homedir}'");
    $svirt->run_cmd("$vbm controlvm $name poweroff");
    $svirt->run_cmd("$vbm unregistervm $name --delete");
    # Remove leftover VM machine folder, and disk(s)
    $svirt->run_cmd("rm -rfv ${homedir}/${name}{,_*.vdi}");

    $svirt->run_cmd("$vbm setproperty vrdeextpack VNC");
    $svirt->run_cmd("$vbm createvm --name $name --register");
    my $ostype         = get_var('VBOXOSTYPE');
    my $longmode       = ($ostype =~ /64/) ? 'on' : 'off';
    my $instance       = 5900 + get_var('VIRSH_INSTANCE');
    my $qemuram        = get_var('QEMURAM');
    my $qemucpus       = get_var('QEMUCPUS');
    my $nictype1       = get_var('VBOXNICTYPE', '82540EM');
    my $vb_serial_port = get_var('VIRTUALBOX_SERIAL_PORT');
    my $storage        = uc(get_var('VBOXHDDTYPE') || 'SATA');
    my $storage_2nd    = uc(get_var('VBOXHDDTYPE2') || $storage);
    my $controller     = get_var('VBOXHDDMODEL') || 'IntelAhci';
    my $controller_2nd = get_var('VBOXHDDMODEL2') || $controller;
    my $usbtype        = get_var('VBOXUSBTYPE', '');                # '' == 'OHCI'
    $svirt->run_cmd("$vbm modifyvm $name --ostype $ostype --boot1 disk --boot2 dvd "
          . "--cpus $qemucpus --longmode $longmode --vtxvpid on "
          . "--memory $qemuram --pagefusion on "
          . "--vrdeproperty VNCPassword=$testapi::password --vrde on --vrdeaddress '' --vrdeport $instance "
          . "--vram 4 --audio pulse --audiocontroller ac97 "
          . "--mouse usbtablet --usb$usbtype on "
          . "--nic1 nat --nictype1 $nictype1 --cableconnected1 on "
          . "--ioapic on --apic on --x2apic off --acpi on --biosapic=apic --rtcuseutc on --paravirtprovider kvm "
          . "--chipset ich9 --uart1 0x3F8 4 --uartmode1 tcpserver $vb_serial_port ");
    $svirt->run_cmd("$vbm storagectl $name --name $storage --add " . lc $storage . " --controller $controller --bootable on --hostiocache on");
    if ($storage ne $storage_2nd) {
        $svirt->run_cmd("$vbm storagectl $name --name $storage_2nd --add " . lc $storage_2nd . " --controller $controller_2nd --bootable on --hostiocache on");
    }
    $svirt->run_cmd("$vbm storageattach $name --storagectl $storage --port 0 --device 0 --type dvddrive --medium " . get_var('ISO'));
    my $numdisks = get_var('NUMDISKS');
    for my $port (1 .. $numdisks) {
        my $hddname = "${homedir}/${name}_${port}";
        $svirt->run_cmd("$vbm createhd --filename $hddname --size " . 1024 * get_var('HDDSIZEGB'));
        $svirt->run_cmd("$vbm storageattach $name --storagectl $storage_2nd --port $port --device 0 "
              . "--type hdd --medium ${hddname}.vdi --nonrotational on --discard on");
    }
    $svirt->run_cmd("$vbm startvm $name --type headless");
    $svirt->run_cmd("netstat -tulpn | grep " . get_var('VIRTUALBOX_SERIAL_PORT'));
    $svirt->run_cmd("netstat -tulpn | grep $instance");
    save_screenshot;

    # Connect to serial port
    $svirt->attach_to_running({name => $name, stop_vm => 1});

    # connects to a guest VNC session
    select_console('sut');
}

1;
