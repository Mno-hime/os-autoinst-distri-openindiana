# OpenIndiana's openQA tests
#
# Copyright © 2018 Michal Nowak
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
    if (my $alternative_publisher = get_var('PKG_ALTERNATIVE_PUBLISHER')) {
        my $alternative_publisher_uri = get_required_var('PKG_ALTERNATIVE_PUBLISHER_URI');
        pkg_call("set-publisher -P -O $alternative_publisher_uri $alternative_publisher", sudo => 1);
        pkg_call('set-publisher --non-sticky openindiana.org',                            sudo => 1);
        pkg_call('publisher');
    }
    pkg_call('update', timeout => 2000, sudo => 1);
    # OpenIndiana releases before 2017.10 have tools which are unable
    # to cope with installing later kernels. Basically, tools before fix
    # for 8142 was integrated are unable to install kernel which has fix
    # for 8685 integraded.
    #
    # So, OpenIndiana 2017.04 (and older) can't be updated directly to
    # OpenIndiana 2018.04 (and later releases). You should update thru
    # OpenIndiana 2017.10, or use the workaround below.
    #
    # For the discussion in full, see:
    #   * https://www.illumos.org/issues/8142
    #   * https://www.illumos.org/issues/8685
    #   * https://illumos.topicbox.com/groups/developer/T441d169a85277364-Md5eecf7b8e4e78766030cfe2
    #   * https://illumos.topicbox.com/groups/developer/Tbd6485b901b93374-M2c975c580ad03866bfaf188e
    my ($base_build) = get_required_var('TEST') =~ /(\d+)/;
    if ($base_build < 20171031) {
        record_soft_failure("We upgrade OpenIndiana from build $base_build, so a workaround is needed.");
        assert_script_sudo('beadm list');
        assert_script_sudo('beadm mount -v openindiana-1 /mnt');
        assert_script_sudo('/mnt/sbin/bootadm update-archive -R /mnt');
        assert_script_sudo('beadm umount /mnt');
    }
    power_action('reboot');
    wait_boot;
    select_console 'user-console' if check_var('DESKTOP', 'textmode');
}

sub test_flags {
    return {fatal => 1, milestone => get_var('PUBLISH_HDD_1') ? 0 : 1};
}

1;

# vim: set sw=4 et:
