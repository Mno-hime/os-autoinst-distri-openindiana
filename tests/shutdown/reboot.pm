# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Update system to latest packages
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'basetest';
use strict;
use testapi;
use utils qw(power_action wait_boot);

sub run {
    if (check_var('DESKTOP', 'mate')) {
        select_console 'x11';
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        select_console 'user-console';
    }
    power_action('reboot');
    wait_boot;
    select_console 'user-console' if check_var('DESKTOP', 'textmode');
}

sub test_flags {
    return {fatal => 1};
}

1;
