# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Use pkgin to install packages (https://pkgsrc.joyent.com/install-on-illumos/)
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;

sub run() {
    select_console 'user-console';

    # Refresh the pkgin database with the latest version
    assert_script_sudo 'pkgin -y update';
    # Search for a package.  Regular expressions are supported.
    assert_script_run 'pkgin search gcc7';
    # Install a package without prompting
    assert_script_sudo 'pkgin -y install gcc7';
    # Make sure ffmpeg binary works
    assert_script_run '/opt/local/gcc7/bin/gcc --version';
    # List all available packages
    assert_script_run '[ $(pkgin avail | wc -l) -gt 16000 ]';
    # Upgrade all out-of-date packages
    assert_script_sudo 'pkgin -y full-upgrade';
    # Remove a package
    assert_script_sudo 'pkgin -y remove gcc7';
    # Automatically remove orphaned dependencies (orphaned after gcc7's removal)
    script_sudo 'pkgin autoremove', 0;
    assert_screen 'pkgin-proceed';
    type_string "Y\n";
    assert_screen 'pkgin-done';
}

1;
