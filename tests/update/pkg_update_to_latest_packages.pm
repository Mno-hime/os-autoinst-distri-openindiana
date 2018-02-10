# OpenIndiana's openQA tests
#
# Copyright © 2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Update system to with packages
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils qw(pkg_call wait_boot power_action);

sub run() {
    if (check_var('DESKTOP', 'mate')) {
        x11_start_program 'xterm';
    }
    else {
        select_console 'user-console';
    }
    if (my $alternative_publisher = get_var('PKG_ALTERNATIVE_PUBLISHER')) {
        my $alternative_publisher_uri = get_required_var('PKG_ALTERNATIVE_PUBLISHER_URI');
        pkg_call("set-publisher -P -O $alternative_publisher_uri $alternative_publisher", sudo => 1);
        pkg_call('set-publisher --non-sticky openindiana.org',                            sudo => 1);
        pkg_call('publisher');
    }
    pkg_call('update', timeout => 2000, sudo => 1);
    power_action('reboot');
    wait_boot;
    select_console 'user-console' if check_var('DESKTOP', 'textmode');
}

sub test_flags {
    return {fatal => 1, milestone => get_var('PUBLISH_HDD_1') ? 0 : 1};
}

1;

# vim: set sw=4 et:
