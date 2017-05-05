# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package installer;

use base Exporter;
use Exporter;

use strict;

use testapi;

our @EXPORT = qw(
  text_installer
);

sub text_installer {
    assert_screen 'welcome-splash-screen';
    send_key 'f6';    # Help
    assert_screen 'help-instructions';
    send_key 'f6';
    assert_screen 'help-topics';
    send_key 'f3';    # Back
    assert_screen 'welcome-splash-screen';
    send_key 'f2';    # Continue/Next
    assert_screen 'disks';
    for (1 .. get_var('NUMDISKS') - 1) { send_key 'down'; send_key 'spc'; }
    assert_screen 'disks-selected-' . get_var('NUMDISKS') . '-numdisks';
    send_key 'f2';
    assert_screen 'gpt-label-warning';
    send_key 'tab';
    send_key 'ret';
    my $partitioning;
    if (get_var('NUMDISKS') == 1) {
        $partitioning = get_var('DISK_PARTITIONING', 'efi');
        send_key_until_needlematch("use-whole-disk-$partitioning", 'down', 2);
        send_key 'f2';
        if (check_var('DISK_PARTITIONING', 'mbr')) {
            assert_screen 'select-partition';
        }
    }
    elsif (get_var('NUMDISKS') == 2) {    # mirror
        assert_screen 'root-pool-type-mirror';
        $partitioning = 'mirror';
    }
    elsif (get_var('NUMDISKS') == 3) {    # raidz
        assert_screen 'root-pool-type-mirror';
        send_key 'down';
        assert_screen 'root-pool-type-raidz';
        $partitioning = 'raidz';
    }
    else {
        die 'Yet to be implemented :)';
    }
    send_key 'f2';
    # illumos hangs when network interface is present under Xen; see bug #7186
    if (check_var('VIRSH_VMM_FAMILY', 'xen')) {
        record_soft_failure '#7186: Network interface is not present';
    }
    else {
        assert_screen 'network-setup';
        for (1 .. 15) { send_key 'backspace'; }
        type_string 'gaiwan';
        send_key 'tab';
        assert_screen 'network-auto-config';
        send_key 'f2';
    }
    assert_screen 'time-zones-regions';
    send_key_until_needlematch('time-zones-regions-europe', 'down');
    send_key 'f2';
    assert_screen 'time-zones-locations';
    send_key_until_needlematch('time-zones-regions-czech-republic', 'down');
    send_key 'f2';
    assert_screen 'time-zones-prague';
    send_key 'f2';
    assert_screen 'date-and-time';
    send_key 'f2';
    assert_screen 'users-setup';
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
    assert_screen 'user-info-entered';
    send_key 'f2';
    assert_screen "installation-overview-$partitioning";
    send_key 'f2';    # Install
    assert_screen 'installing-openindiana', 300;
    assert_screen 'installation-complete',  1000;
    send_key 'f4';    # View log
    assert_screen 'installation-log';
    send_key 'f3';    # Back
    assert_screen 'installation-complete';
}
