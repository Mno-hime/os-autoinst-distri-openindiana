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
use utils qw(bootloader_dvd firstboot_setup mate_change_resolution_1024_768);
use installer 'text_installer';

sub run() {
    bootloader_dvd;
    firstboot_setup;
    # For releases before and including 20161030 OI can't use cirrus driver and therefor
    # boots to 1280x768 px resolution, but we need to get to 1024x768 somehow.
    if (!check_var('QEMUVGA', 'cirrus')) {
        assert_screen 'mate-desktop-1280x768', 200;
        wait_still_screen;
        # Close About GNOME window
        if (get_var('BUILD') <= 20160421) {
            send_key 'alt-c';
        }
        mate_change_resolution_1024_768;
    }
    else {
        assert_screen 'mate-desktop', 200;
        wait_still_screen;
    }


    my $installer = get_var('INSTALLER', 'gui');
    # GUI installer
    if ($installer eq 'gui') {
        x11_start_program '/usr/bin/sudo /usr/bin/gui-install';
        assert_screen 'mate-openindiana-gui-installer';
        send_key 'ret';
        # Open release notes in Firefox
        assert_screen 'firefox-openindiana-release-notes';
        send_key 'ctrl-w';
        assert_screen 'mate-openindiana-gui-installer';
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

        assert_screen 'installation-finished', 1000;
        # List thru installation log
        send_key_until_needlematch('select-installation-log', 'tab');
        send_key 'ret';
        assert_screen 'installation-log';
        wait_screen_change { send_key 'pgdn' };
        send_key 'alt-c';
        assert_screen 'installation-finished';
        # Restart to installed system
        send_key 'alt-r';
    }
    elsif ($installer eq 'text') {
        x11_start_program('/usr/bin/sudo /usr/bin/text-install', undef, {terminal => 1});
        text_installer;
        send_key 'f8';
    }
}

1;

# vim: set sw=4 et:
