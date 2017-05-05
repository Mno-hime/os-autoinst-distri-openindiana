# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: p5p package archive test
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run() {
    select_console 'user-console';

    assert_script_run('pkgrecv -s https://pkg.openindiana.org/hipster -d zsh.p5p -a -r pkg://openindiana.org/shell/zsh', 1000);
    assert_script_run('pkgrepo -s zsh.p5p list');
    pkg_call('list -f -g zsh.p5p');
    pkg_call('set-publisher -p zsh.p5p', sudo => 1);
    pkg_call('publisher | grep zsh');

    # TODO: install zsh from the new publisher
    #pkg_call('uninstall zsh');
    #pkg_call('install zsh');

    # Clean up
    pkg_call('set-publisher -G file://${HOME}/zsh.p5p openindiana.org', sudo => 1);
    pkg_call('publisher | grep -v zsh');
    assert_script_run('rm zsh.p5p');
}

1;

# vim: set sw=4 et:
