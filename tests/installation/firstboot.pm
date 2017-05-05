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

use base 'consoletest';
use strict;
use testapi;
use utils;

sub run {
    my ($self) = @_;
    wait_boot;
    console_login if check_var('DESKTOP', 'textmode');

    if (check_var('DESKTOP', 'textmode')) {
        clear_and_verify_console;
        type_string "su -\n";
        assert_screen 'console-login-password';
        type_password;
        send_key 'ret';
        if (get_var('FLAVOR', '') =~ /Minimal/) {
            # Can't use pkg_call() as we don't have sudo, yet.
            assert_script_run('pkg install sudo wget', 200);
        }
        else {
            assert_script_run("sed -i '/$testapi::username/d' /etc/sudoers");
        }
        assert_script_run "echo '$testapi::username ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers";
        type_string "exit\n";
        type_string "clear; exit\n";
        assert_screen 'console-login';
        type_string "$testapi::username\n";
        assert_screen 'console-login-password';
        type_password;
        send_key 'ret';
    }
    elsif (check_var('DESKTOP', 'mate')) {
        if (!check_var('QEMUVGA', 'cirrus') and !check_var('VIRSH_VMM_FAMILY', 'virtualbox')) {
            assert_screen 'mate-desktop-1280x768', 90;
            wait_still_screen;
            mate_change_resolution_1024_768;
        }
        else {
            match_mate_desktop;
            wait_still_screen;
        }
        mouse_hide;

        x11_start_program 'xterm';
        # Disable xscreensaver
        assert_script_run 'mkdir -p .config/autostart/; cat /etc/xdg/autostart/xscreensaver.desktop > ~/.config/autostart/xscreensaver.desktop';
        assert_script_run 'echo "X-MATE-Autostart-enabled=false" >> .config/autostart/xscreensaver.desktop';
        # Should actually be `assert_script_run`, but the verification string
        # is offen incorrectly written.
        script_run 'xscreensaver-command -exit';
        script_run 'sudo visudo', 0;
        assert_screen('password-prompt');
        type_password;
        send_key('ret');
        assert_screen('visudo-running');
        type_string 'Gcc';
        type_string "$testapi::username ALL=(ALL) NOPASSWD: ALL";
        send_key 'esc';
        type_string 'ZZ';
        type_string "exit\n";    # Quit XTerm
        x11_start_program 'xterm';
    }

    type_string "PS1='\$ '\n";
    type_string "clear\n";
    assert_screen('cleared-console');

    # Enable Virtual Terminals 2..6
    enable_vt;
    # Enable console mirroring to first serial console
    assert_script_sudo "/usr/sbin/consadm -a -p /dev/$testapi::serialdev";
    # Assigning RBAC profile to the build user, and re-login to take effect
    assert_script_sudo "/usr/sbin/usermod -P'Primary Administrator' $testapi::username";
    select_console 'user-console' if check_var('DESKTOP', 'textmode');

    if (check_var('DESKTOP', 'mate')) {
        type_string "exit\n";    # exit xterm
        if (!check_var('QEMUVGA', 'cirrus') and !check_var('VIRSH_VMM_FAMILY', 'virtualbox')) {
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

sub test_flags() {
    return {fatal => 1, milestone => 1};
}

1;
