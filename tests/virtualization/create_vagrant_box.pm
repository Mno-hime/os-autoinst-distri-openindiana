# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Create a Vagrant box from uploaded image
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run {
    select_console 'user-console';

    my $virt = check_var('BACKEND', 'qemu') ? 'kvm' : get_required_var('VIRSH_VMM_FAMILY');
    assert_script_run "export PACKER_BUILDER_TYPE=$virt";

    if (check_var('VIRSH_VMM_FAMILY', 'virtualbox')) {
        # VirtualBox version we run on host
        my $vboxver = '5.2.4';
        assert_script_run 'wget -O VBoxGuestAdditions.iso ' . data_url("vagrant/VBoxGuestAdditions_$vboxver.iso");
    }
    # Configure guest management tools, environment for `vagrant up`, & cleanup
    for my $script ('vmtools', 'vagrant', 'cleanup', 'openqa_cleanup') {
        assert_script_run 'wget ' . data_url("vagrant/$script.sh");
        assert_script_run "chmod +x $script.sh";
        assert_script_sudo "-E ./$script.sh";
        assert_script_run "rm $script.sh";
    }
}

sub test_flags() {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
