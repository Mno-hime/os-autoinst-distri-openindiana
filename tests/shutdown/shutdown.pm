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

use base 'basetest';
use strict;
use testapi;
use utils qw(power_action system_log_gathering);

sub run() {
    select_console 'user-console';
    system_log_gathering;
    select_console 'x11' if check_var('DESKTOP', 'mate');
    power_action('poweroff');
}

1;

# vim: set sw=4 et:
