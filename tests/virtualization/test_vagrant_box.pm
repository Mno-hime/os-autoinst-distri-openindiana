# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Test created Vagrant box
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;

sub run {
    select_console 'svirt';

    my $image_storage = '/var/lib/libvirt/images';
    type_string("clear\n");
    type_string "pushd $image_storage\n";
    sleep 2;
    type_string "vagrant box remove -f -a openindiana_hipster_test\n";
    sleep 5;
    my $vagrant_name           = get_required_var('PUBLISH_HDD_1');
    type_string "vagrant box add --name openindiana_hipster_test $vagrant_name\n";
    assert_screen "vagrant-box-add", 600;
    type_string "vagrant box list -i\n";
    sleep 2;
    type_string "vagrant init openindiana_hipster_test\n";
    assert_screen "vagrant-init", 600;
    type_string "vagrant up\n";
    assert_screen "vagrant-up", 600;
    type_string "vagrant ssh\n";
    assert_screen "vagrant-ssh", 200;
    type_string "ping google.com\n";
    assert_screen "ping-google-com-alive";
    type_string "exit\n";
    sleep 5;
    type_string "vagrant halt\n";
    assert_screen "vagrant-halt", 200;
    type_string "vagrant destroy -f\n";
    assert_screen "vagrant-destroy";
    type_string "vagrant box remove -f -a openindiana_hipster_test\n";
    sleep 5;
}

sub test_flags() {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
