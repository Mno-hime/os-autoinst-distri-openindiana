# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Boot to new Boot Environment
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils qw(pkg_call wait_boot);

sub run() {
    select_console 'root-console';

    my $get_nr_be = 'beadm list | grep -w NR | awk \'{ print $1 }\'';
    my $get_r_be  = 'beadm list | grep -w R | awk \'{ print $1 }\'';
    my $get_n_be  = 'beadm list | grep -w N | awk \'{ print $1 }\'';

    # Install updates to new BE, reboot to it and verify we are there
    my $original_active_be = script_output($get_nr_be);
    my $ret                = pkg_call('update --require-new-be');
    if ($ret eq 4) {
        record_info('pkg_call returned "4"', 'Nothing to do; quit', result => 'softfail');
        return 1;
    }
    my $active_be_after_reboot = script_output('beadm list | grep -w R | awk \'{ print $1 }\'');
    type_string "reboot\n";
    reset_consoles;
    wait_boot;
    select_console 'root-console';
    my $new_active_be     = script_output($get_nr_be);
    my $new_active_be_bkp = $new_active_be;
    die "We booted to '$new_active_be' BE, but should boot to '$active_be_after_reboot' BE" unless ($active_be_after_reboot eq $new_active_be);

    # Activate old BE, boot to it and verify we are in it
    assert_script_run("beadm activate $original_active_be");
    $active_be_after_reboot = script_output('beadm list | grep -w R | awk \'{ print $1 }\'');
    type_string "reboot\n";
    reset_consoles;
    wait_boot;
    select_console 'root-console';
    $new_active_be = script_output($get_nr_be);
    die "We booted to '$new_active_be' BE, but should boot to '$active_be_after_reboot' BE" unless ($active_be_after_reboot eq $new_active_be);

    # Destroy BE with updates
    assert_script_run("beadm destroy -F -s -v $new_active_be_bkp");
    assert_script_run("! beadm destroy -F -s -v $original_active_be");
    assert_script_run("beadm list");
}

sub test_flags() {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
