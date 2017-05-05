# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Test pkg repository commands
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run() {
    select_console 'root-console';

    pkg_call('publisher');
    pkg_call('set-publisher -O http://pkg.openindiana.org/hipster-encumbered hipster-encumbered');
    pkg_call('publisher');
    pkg_call('list xvid', exitcode => [1]);
    pkg_call('install xvid');
    pkg_call('list xvid');
    pkg_call('unset-publisher hipster-encumbered');
    pkg_call('publisher');
    pkg_call('list xvid');
    pkg_call('uninstall xvid');
    pkg_call('list xvid', exitcode => [1]);
    assert_script_run('pkgrepo info -s https://pkg.openindiana.org/hipster/');
    assert_script_run('pkgrepo list -s https://pkg.openindiana.org/hipster/ xorg-video-cirrus');
    pkg_call('history');
}

1;

# vim: set sw=4 et:
