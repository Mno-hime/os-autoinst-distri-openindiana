# OpenIndiana's openQA tests
#
# Copyright © 2016-2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Upload svirt assets
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use warnings;
use testapi;

sub extract_assets {
    my ($args) = @_;

    my $name           = $args->{name};
    my $format         = $args->{format};
    my $image_storage  = '/var/lib/libvirt/images';
    my $suffix         = check_var('VIRSH_VMM_FAMILY', 'virtualbox') ? '.vdi' : '.img';
    my $svirt_img_name = $image_storage . '/' . $args->{svirt_name} . $suffix;

    type_string("clear\n");
    type_string "pushd $image_storage\n";
    sleep 2;
    type_string("test -e $svirt_img_name && echo 'OK'\n");
    assert_screen('svirt-asset-upload-hdd-image-exists');

    my $cmd;
    if (check_var('BACKEND', 'qemu')) {
        $cmd = "nice ionice qemu-img convert -p -O $format $svirt_img_name $name";
        $cmd .= ' -c' if get_var('QEMU_COMPRESS_QCOW2');
        type_string("$cmd && echo OK\n");
        assert_screen('svirt-asset-upload-hdd-image-converted', 600);
    }
    elsif (check_var('VIRSH_VMM_FAMILY', 'virtualbox')) {
        if (check_var('VAGRANT_BOX', 'create')) {
            $name =~ s/\.([[:alnum:]]+)$//;
            type_string "rm -fv metadata.json Vagrantfile box.ovf box-disk002.vmdk\n";
            sleep 3;
            my $i = get_required_var('VIRSH_INSTANCE');
            type_string "MAC=\$(VBoxManage showvminfo openQA-SUT-$i | grep 'NIC 1:' | awk '{ print \$4 }' | tr -d '\\n,')\n";
            type_string "echo \$MAC\n";
            my $build = get_required_var('BUILD');
            type_string '
echo "Vagrant.configure(\"2\") do |config|
    config.vm.box = \"openindiana/hipster\"
    config.vm.box_version = \"' . $build . '\"
    config.vm.base_mac = \"$MAC\"
end" > Vagrantfile';
            send_key 'ret';
            sleep 3;
            type_string 'echo {\\"provider\\":\\"virtualbox\\"} > metadata.json';
            send_key 'ret';
            sleep 3;
            type_string "VBoxManage export openQA-SUT-$i -o box.ovf\n";
            assert_screen('svirt-asset-upload-hdd-image-exported', 1000);
            $name .= '.box';
            type_string "GZIP=-9 nice ionice tar cvvfz $name Vagrantfile metadata.json box.ovf box-disk002.vmdk && echo BOX-CREATION-OK\n";
            assert_screen('svirt-asset-upload-hdd-image-gzipped', 1000);
            type_string "rm -fv metadata.json Vagrantfile box.ovf box-disk002.vmdk\n";
        }
        else {
            type_string "DISK_UUID=\$(VBoxManage showmediuminfo disk $svirt_img_name | grep 'Child UUIDs' | awk '{ print \$3 }' | tr -d '\\n')\n";
            type_string "echo \$DISK_UUID\n";
            type_string "nice ionice VBoxManage clonemedium disk \$DISK_UUID $name && echo OK\n";
            assert_screen('svirt-asset-upload-hdd-image-converted', 600);
        }
    }
    else {
        die 'Unsupported hypervizor wrt uploading?';
    }

    # Upload the image as a private asset; do the upload verification
    # on your own - hence the following assert_screen().
    upload_asset("$name", 1, 1);
    assert_screen('svirt-asset-upload-hdd-image-uploaded', 1000);
}

sub run {
    # connect to VIRSH_HOSTNAME screen and upload asset from there
    my $svirt = select_console('svirt');

    # mark hard disks for upload if test finished
    my @toextract;
    my $first_hdd = get_var('S390_ZKVM') ? 'a' : 'b';
    for my $i (1 .. get_var('NUMDISKS')) {
        my $name = get_var("PUBLISH_HDD_$i");
        next unless $name;
        $name =~ /\.([[:alnum:]]+)$/;
        my $format = $1;
        if (($format ne 'raw') and ($format ne 'qcow2') and ($format ne 'vdi') and ($format ne 'box')) {
            next;
        }
        $format = check_var('VIRSH_VMM_FAMILY', 'virtualbox') ? 'vdi' : 'qcow2';
        $name =~ s/\.([[:alnum:]]+)$/\.vdi/ if check_var('VIRSH_VMM_FAMILY', 'virtualbox');
        diag "name=$name";
        my $drive_designation = check_var('VIRSH_VMM_FAMILY', 'virtualbox') ? "_$i" : chr(ord($first_hdd) + $i - 1);
        push @toextract, {name => $name, format => $format, svirt_name => $svirt->name . $drive_designation};
    }
    for my $asset (@toextract) {
        extract_assets($asset);
    }
}

sub test_flags() {
    return {fatal => 1};
}

1;
