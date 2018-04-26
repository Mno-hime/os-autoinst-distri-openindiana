# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Use pkg_* tools to manage packages (https://pkgsrc.joyent.com/install-on-illumos/)
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;

sub run {
    select_console 'user-console';

    # See what packages are installed.
    assert_script_run 'pkg_info';
    # Get info about openssl package.
    assert_script_run 'pkg_info openssl';
    # List the contents of openssl package (limited to first 10 lines).
    assert_script_run 'pkg_info -qL openssl | head -n 10';
    # See what package file `/opt/local/bin/openssl` belongs to.
    assert_script_run 'pkg_info -Fe /opt/local/bin/openssl';
    # Perform an audit of all currently installed packages.
    assert_script_sudo 'pkg_admin fetch-pkg-vulnerabilities', 300;
    assert_script_run '! pkg_admin audit';    # There are for sure some :).

    # Upgrade all out-of-date packages.
    assert_script_sudo 'pkgin -y full-upgrade';
}

1;
