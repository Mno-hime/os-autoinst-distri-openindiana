# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Boot from HDD image
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;
use utils 'wait_boot';

sub run {
    wait_boot;
}

sub test_flags {
    return {fatal => 1, milestone => get_var('PUBLISH_HDD_1') ? 0 : 1};
}

1;

# vim: set sw=4 et:
