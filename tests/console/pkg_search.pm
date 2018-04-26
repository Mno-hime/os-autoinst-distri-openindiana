# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Test 'search' command of pkg
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run {
    select_console 'user-console';

    pkg_call('rebuild-index', sudo => 1);
    pkg_call('publisher');
    pkg_call('search zsh');
    pkg_call('search -p zsh');
    pkg_call('search NonExistent',         exitcode => [1]);
    pkg_call('search -l /usr/bin/hexchat', exitcode => [1]);
    pkg_call('search -l -r /usr/bin/hexchat');
}

1;

# vim: set sw=4 et:
