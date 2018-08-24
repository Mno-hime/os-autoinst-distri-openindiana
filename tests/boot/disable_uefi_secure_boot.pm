# OpenIndiana's openQA tests
#
# Copyright © 2018 Michal Nowak
# Copyright © 2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Disable UEFI Secure Boot
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;

sub run {
    assert_screen('uefi-firmware-banner');
    # we need to reduce this waiting time as much as possible
    while (!check_screen('uefi-menu-home', 0, no_wait => 1)) {
        send_key 'f2';
        sleep 0.1;
    }
    send_key 'down';
    send_key 'ret';
    assert_screen('uefi-menu-device-manager');
    send_key 'ret';
    assert_screen('uefi-menu-secure-boot-configuration');
    send_key 'down';
    send_key 'ret';
    assert_screen('uefi-menu-secure-boot-configuration-changed');
    send_key 'ret';
    send_key 'f10';
    assert_screen('uefi-menu-save-configuration');
    send_key 'y';
    send_key 'esc';
    assert_screen('uefi-menu-device-manager');
    send_key 'esc';
    send_key_until_needlematch('uefi-menu-home-continue-button', 'down', 10);
    send_key 'ret';
    assert_screen('uefi-menu-reset-now');
    send_key 'ret';
    assert_screen('uefi-firmware-banner');
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
