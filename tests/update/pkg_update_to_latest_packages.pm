# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Update system to with packages
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils qw(pkg_call wait_boot power_action);

sub run() {
    if (check_var('DESKTOP', 'mate')) {
        x11_start_program 'xterm';
    }
    else {
        select_console 'user-console';
    }
    if (get_var('BUILD') <= 20160421) {
        # Workaround for illumos#7320. Fixed in pkg5 d656c89bea755e0065d34c0aa15ae9ed1ea3eec4.
        # See https://www.openindiana.org/2016/08/29/possible-ssh-update-issue/ as well.
        assert_script_sudo('echo >> /etc/ssh/sshd_config')
          && record_soft_failure('illumos#7320: Update failed following Sun SSH deprecation');
    }
    pkg_call('update', timeout => 2000, sudo => 1);
    power_action('reboot');
    wait_boot;
    select_console 'user-console' if check_var('DESKTOP', 'textmode');
}

sub test_flags() {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
