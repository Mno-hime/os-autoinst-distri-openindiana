# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: OpenIndiana text mode installation
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;
use utils;
use installer 'text_installer';

sub run {
    pre_bootmenu_setup;
    bootloader_dvd if get_var('BUILD') >= 20161030;
    firstboot_setup;
    assert_screen 'installation-menu';
    send_key '3';
    send_key 'ret';
    sleep 30;
    type_string "clear\n";
    type_string "tail -F /tmp/install_log > /dev/$testapi::serialdev &\n";
    type_string "exit\n";
    assert_screen 'installation-menu';
    send_key 'ret';

    text_installer;

    send_key 'f9';    # Quit
    assert_screen 'installation-menu';
    wait_idle;        # Sometimes the '3\n' did not make it on i386
    send_key '3';
    send_key 'ret';
    assert_screen 'vt-installation';

    # Upload various logs
    unless (check_var('VIRSH_VMM_FAMILY', 'xen')) {
        upload_logs('/tmp/install_log');
        system_log_gathering(nosudo => 1);
    }
    power_action('reboot', nosudo => 1);
}

1;
