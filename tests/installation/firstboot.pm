# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: OpenIndiana bootloader
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;
use utils qw(enable_vt mate_change_resolution_1024_768 wait_boot activate_root_account);

sub run() {
    wait_boot;

    if (check_var('FLAVOR', 'Minimal')) {
        sleep 3;
        type_string "su -\n";
        sleep 3;
        type_password;
        send_key 'ret';
        # Can't use pkg_call() as we don't have sudo, yet.
        assert_script_run 'pkg install sudo wget', 700;
        assert_script_run "echo '$testapi::username ALL=(ALL) ALL' >> /etc/sudoers";
        type_string "exit\n";
        sleep 20;
        type_string "clear\n";
        type_string "exit\n";
        assert_screen 'console-login';
        type_string "$testapi::username\n";
        assert_screen 'console-login-password';
        type_password;
        send_key 'ret';
        sleep 10;
    }
    if (check_var('DESKTOP', 'mate')) {
        if (!check_var('QEMUVGA', 'cirrus')) {
            assert_screen 'mate-desktop-1280x768', 90;
            wait_still_screen;
            mate_change_resolution_1024_768;
        }
        else {
            assert_screen 'mate-desktop', 90;
            wait_still_screen;
        }

        x11_start_program 'xterm';
        # Disable xscreensaver
        assert_script_run 'mkdir -p .config/autostart/; cat /etc/xdg/autostart/xscreensaver.desktop > ~/.config/autostart/xscreensaver.desktop';
        assert_script_run 'echo "X-MATE-Autostart-enabled=false" >> .config/autostart/xscreensaver.desktop';
        assert_script_run 'xscreensaver-command -exit';
    }

    type_string "PS1='\$ '\n";
    # Enable Virtual Terminals 2..6
    enable_vt;
    # Enable console mirroring to first serial console
    assert_script_sudo "/usr/sbin/consadm -a -p /dev/$testapi::serialdev";
    # Assigning RBAC profile to the build user, and re-login to take effect
    assert_script_sudo "/usr/sbin/usermod -P'Primary Administrator' $testapi::username";
    select_console 'root-console' if check_var('DESKTOP', 'textmode');

    if (check_var('DESKTOP', 'mate')) {
        type_string "exit\n";    # exit xterm
        if (!check_var('QEMUVGA', 'cirrus')) {
            # Make 1024x768 resolution permanent
            x11_start_program 'mate-display-properties';
            assert_screen 'mate-display-properties';
            send_key 'alt-a';
            assert_screen 'display-looks-ok';
            send_key 'ret';
            assert_screen 'mate-display-properties';
            send_key 'alt-c';
        }
    }
}

1;
