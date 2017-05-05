# OpenIndiana's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2017 SUSE LLC
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use strict;
use warnings;
use testapi qw(check_var get_var get_required_var set_var);
use needle;
use File::Basename;

BEGIN {
    unshift @INC, dirname(__FILE__) . '/../../lib';
}

use main_common;

init_main();

my $distri = testapi::get_var('CASEDIR') . '/lib/openindianadistribution.pm';
require $distri;
testapi::set_distribution(openindianadistribution->new());

set_var('SERIALDEV', 'ttya');

sub load_consoletests() {
    loadtest 'console/pkg_search';
    loadtest 'console/pkg_listing';
    loadtest 'console/pkg_install';
    loadtest 'console/pkg_uninstall';
    loadtest 'console/pkg_repository';
    loadtest 'console/pkg_p5p_package_archive';
    loadtest 'console/be_boot_to_new_be' unless get_var('UPDATE');
}

if (get_var('HDD_1')) {
    loadtest 'boot/boot_from_hdd';
    if (get_var('UPDATE')) {
        loadtest 'update/pkg_update_to_latest_packages';
        loadtest 'shutdown/reboot';
    }
    if (get_var('TOOLCHAIN')) {
        loadtest 'toolchain/building_with_oi_userland';
        loadtest 'toolchain/distribution_constructor' if check_var('ARCH', 'x86_64');
    }
    if (get_var('VIRTUALIZATION')) {
        loadtest 'virtualization/kvm_boot_alpine';
        loadtest 'virtualization/kvm_boot_firefly';
    }
}
else {
    if (check_var('VIRSH_VMM_FAMILY', 'xen') or check_var('VIRSH_VMM_FAMILY', 'virtualbox')) {
        loadtest 'installation/bootloader_' . get_var('VIRSH_VMM_FAMILY');
    }
    if (get_var('BOOTLOADER_REGRESSION_FEATURE')) {
        loadtest 'regressions/' . get_required_var('BOOTLOADER_REGRESSION_FEATURE');
        return 1;
    }
    loadtest 'installation/bootloader_' . get_var('DESKTOP');
    loadtest 'installation/redefine_svirt_domain' if check_var('VIRSH_VMM_FAMILY', 'xen');
    loadtest 'installation/firstboot';
    loadtest 'installation/zpool_rpool_setup';
}
if (get_var('PUBLISH_HDD_1')) {
    load_consoletests;
}
loadtest 'shutdown/shutdown';

1;
# vim: set sw=4 et:
