# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Verify 'rpool' was setup correctly
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;

sub run {
    select_console 'user-console';

    assert_script_run 'zpool status';
    assert_script_run 'zpool status | grep "No known data errors"';
    assert_script_run 'zpool status | grep ' . get_var('ROOT_POOL_TYPE') if get_var('ROOT_POOL_TYPE');
}

sub test_flags {
    return {milestone => get_var('PUBLISH_HDD_1') ? 0 : 1};
}

1;

# vim: set sw=4 et:
