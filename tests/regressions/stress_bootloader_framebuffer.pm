# OpenIndiana's openQA tests
#
# Copyright © 2017-2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Stress-test bootloader's framebuffer support
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;

sub run {
    assert_screen 'sea-bios-splash';
    assert_screen 'bootloader-menu-main-screen-media-boot-textmode';
    send_key '3';
    assert_screen 'ok-shell-framebuffer';

    my @fbmodes;
    my $vga = get_var('QEMUVGA', 'cirrus');
    if ($vga eq 'cirrus') {
        @fbmodes = (
            '101', '111', '110', '112',
            '103', '114', '113', '105',
            '117', '116', '115', '118',
            '107', '119', '11a'    #'13'
        );
    }
    elsif ($vga eq 'qxl') {
        @fbmodes = (
            '100', '101', '103', '105', '107', '10d', '10e', '10f', '110', '111', '112', '113', '114', '115', '116', '117', '118', '119',
            '11a', '11b', '11c', '11d', '11e', '11f', '140', '141', '142', '143', '144', '145', '146', '147', '148', '149', '14a', '14b',
            '14c', '175', '176', '177', '178', '179', '17a', '17b', '17c', '17d', '17e', '17f', '180', '181', '182', '183', '184', '185',
            '186', '187', '188', '189', '18a', '18b', '18c', '18d', '18e', '18f', '190', '191', '192'
        );
    }
    my $fbmodes_size = scalar @fbmodes;
    my $oldindex     = $fbmodes_size;
    for (1 .. 100) {
        my $index = int rand($fbmodes_size - 1);
        next if ($index == $oldindex);
        my $mode = $fbmodes[$index];
        type_string "framebuffer set 0x$mode\n";
        assert_screen 'all-white-screen', 5;
        $oldindex = $index;
    }
}

sub post_fail_hook {
    type_string "show screen-font\n";
    sleep 5;
    save_screenshot;
}

1;

# vim: set sw=4 et:
