# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package installbasetest;
use base 'openindianabasetest';
use strict;
use utils 'system_log_gathering';
use installer 'quit_installer';
use testapi;

sub post_fail_hook {
    if (check_var('DESKTOP', 'textmode')) {
        if (check_screen('text-installer-still-running')) {
            quit_installer;
            # Login to install shell
            send_key '3';
            send_key 'ret';
            assert_screen 'vt-installation';
        }
        system_log_gathering(nosudo => 1);
    }
    elsif (check_var('DESKTOP', 'mate')) {
        x11_start_program('sudo xterm');
        assert_screen 'xterm-started';
        system_log_gathering(nosudo => 1);
    }
}

# All steps in the installation are 'fatal'.
sub test_flags {
    return {fatal => 1};
}

1;
# vim: set sw=4 et:
