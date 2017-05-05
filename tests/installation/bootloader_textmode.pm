# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
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
use utils qw(bootloader_dvd firstboot_setup reboot save_and_upload_log system_log_gathering);
use installer 'text_installer';

sub run() {
    bootloader_dvd if get_var('BUILD') >= 20161030;
    firstboot_setup;
    assert_screen 'installation-menu';
    send_key '3';
    send_key 'ret';
    sleep 60;    # Sleep to get rid of some visual disturbances
    type_string "tail -F /tmp/install_log > /dev/$testapi::serialdev &\n";
    type_string "exit\n";
    assert_screen 'installation-menu';
    send_key 'ret';

    text_installer;

    send_key 'f9';    # Quit
    assert_screen 'installation-menu';
    send_key '3';
    send_key 'ret';
    assert_screen 'vt-installation';

    # Upload various logs
    if (check_var('VIRSH_VMM_FAMILY', 'xen')) {
        type_string "poweroff\n";
        sleep 30;
        #assert_shutdown;
        reset_consoles;
        sleep 30;
    }
    else {
        assert_script_run 'cp /tmp/install_log /tmp/install_log.txt';
        upload_logs('/tmp/install_log.txt');
        system_log_gathering;
        # Restart
        type_string "exit\n";
        send_key '5';
        send_key 'ret';
    }
}

1;
