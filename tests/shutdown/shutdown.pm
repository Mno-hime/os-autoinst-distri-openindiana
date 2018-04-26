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
use utils qw(power_action system_log_gathering);

sub run {
    select_console 'user-console';
    # On Vagrant boxes user 'robot' is by now gone.
    system_log_gathering unless check_var('VAGRANT_BOX', 'create');
    select_console 'x11'                                      if check_var('DESKTOP',     'mate');
    assert_script_sudo "/usr/sbin/userdel $testapi::username" if check_var('VAGRANT_BOX', 'create');
    power_action('poweroff');
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
