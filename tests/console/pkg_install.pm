# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Test pkg 'install' command
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run() {
    select_console 'root-console';

    pkg_call('list dash', exitcode => [1]);
    pkg_call('install dash');
    pkg_call('list dash');
}

1;

# vim: set sw=4 et:
