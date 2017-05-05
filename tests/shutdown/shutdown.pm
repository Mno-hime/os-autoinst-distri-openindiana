# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Update system to latest packages
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;
use utils qw(poweroff system_log_gathering);

sub run() {
    select_console 'root-console';
    system_log_gathering;
    if (check_var('DESKTOP', 'mate')) {
        select_console 'x11';
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        select_console 'root-console';
    }
    poweroff;
    assert_shutdown(90);
}

1;

# vim: set sw=4 et:
