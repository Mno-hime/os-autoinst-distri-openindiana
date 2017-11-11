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
use utils;
use installer 'text_installer';

sub run() {
    pre_bootmenu_setup;
    bootloader_dvd;
    firstboot_setup;
    # LightDM login is not present on Live medium
    assert_mate;
    mouse_hide;

    my $installer = get_var('INSTALLER', 'gui');
    # GUI installer
    if ($installer eq 'gui') {
        x11_start_program '/usr/bin/sudo /usr/bin/gui-install';
        assert_screen 'mate-openindiana-gui-installer';
        unless (check_var('VIRSH_VMM_FAMILY', 'xen')) {
            send_key 'ret';
            # Open release notes in Firefox
            my $tag = check_screen([qw(firefox-reader-view firefox-openindiana-release-notes)], 90);
            if (match_has_tag('firefox-reader-view')) {
                for (1 .. 10) {
                    last if (wait_screen_change { assert_and_click('firefox-reader-view-close-button', 'left', 10, 2); });
                }
            }
            assert_screen('firefox-openindiana-release-notes');
            send_key 'ctrl-w';
            assert_screen 'mate-openindiana-gui-installer';
        }
        # Show installation help
        send_key 'alt-h';
        assert_screen 'installer-help';
        send_key 'alt-c';
        assert_screen 'mate-openindiana-gui-installer';
        send_key 'alt-n';
        # Disk partitioning
        assert_screen 'disk-partitioning';
        my $partitioning = get_var('DISK_PARTITIONING', 'mbr');
        if ($partitioning eq 'mbr') {
            assert_screen 'disk-partitioning-disk-partition';
        }
        elsif ($partitioning eq 'efi') {
            send_key 'alt-w';
            assert_screen 'disk-partitioning-efi';
        }
        send_key 'alt-n';
        # Time zones & co.
        assert_screen 'time-zone';
        send_key 'alt-r';
        send_key_until_needlematch('time-zone-europa', 'down');
        send_key 'alt-l';
        type_string 'c';
        send_key_until_needlematch('time-zone-czech-republic', 'down');
        send_key 'alt-n';
        # Locale
        assert_screen 'locale-english';
        send_key 'alt-t';
        send_key 'end';
        send_key_until_needlematch('locale-territory-us', 'up');
        send_key 'alt-n';
        # Setup users
        assert_screen 'user-setup';
        send_key 'alt-n';
        assert_screen 'user-setup-no-password';
        send_key 'alt-c';
        assert_screen 'user-setup';
        send_key 'alt-r';
        type_password;
        send_key 'tab';
        type_password;
        send_key 'tab';
        type_string $testapi::realname;
        send_key 'tab';
        type_string $testapi::username;
        send_key 'tab';
        type_password;
        send_key 'tab';
        type_password;
        send_key 'tab';
        type_string 'gaiwan';
        send_key 'alt-n';
        # Installation overview
        assert_screen 'installation-overview';
        # Start the actual installation
        send_key 'alt-i';

        # Make sure error window about volume mounting is closed
        if (check_screen('cannot-mount-volume')) {
            send_key 'alt-o';
        }

        # Installation from USB (EHCI-only currently) is really slow
        assert_screen 'installation-finished', (get_var('USBBOOT') || check_var('VBOXHDDTYPE2', 'usb')) ? 3000 : 1200;
        # List thru installation log
        send_key_until_needlematch('select-installation-log', 'tab');
        send_key 'ret';
        assert_screen 'installation-log';
        wait_screen_change { send_key 'pgdn' };
        send_key 'alt-c';
        assert_screen 'installation-finished';
        send_key 'alt-q';    # Quit
        assert_screen 'quit-installation';
        send_key 'alt-o';    # OK
    }
    elsif ($installer eq 'text') {
        x11_start_program('/usr/bin/sudo /usr/bin/text-install', undef, {terminal => 1});
        text_installer;
        send_key 'f9';       # Quit text installer
    }
    x11_start_program('xterm');
    system_log_gathering;
    type_string "exit\n";
    power_action('reboot');
}

1;

# vim: set sw=4 et:
