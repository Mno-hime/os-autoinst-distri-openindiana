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

our %features = map { $_ => 1 } split /,/, get_var('FEATURES', '');

sub load_consoletests {
    loadtest 'console/pkg_search';
    loadtest 'console/pkg_listing';
    loadtest 'console/pkg_install';
    loadtest 'console/pkg_uninstall';
    loadtest 'console/pkg_repository';
    loadtest 'console/pkg_p5p_package_archive';
    loadtest 'console/be_boot_to_new_be' unless exists $features{update};
}

sub load_featuretests {
    if (%features) {
        if (exists $features{update}) {
            loadtest 'update/pkg_update_to_latest_packages';
            load_consoletests;
        }
        if (exists $features{toolchain}) {
            loadtest 'toolchain/pkgsrc_deploy';
            loadtest 'toolchain/pkgsrc_pkgin_install_packages';
            loadtest 'toolchain/pkgsrc_manage_packages';
            loadtest 'toolchain/building_with_oi_userland';
        }
        if (exists $features{distribution_constructor}) {
            loadtest 'toolchain/distribution_constructor';
        }
        if (exists $features{virtualization}) {
            loadtest 'virtualization/kvm_boot_alpine';
            loadtest 'virtualization/kvm_boot_firefly';
        }
        if (exists $features{consoletests}) {
            load_consoletests;
        }
    }
}

my $vmm_family = get_var('VIRSH_VMM_FAMILY');
my $desktop    = get_required_var('DESKTOP');
my $brf        = get_var('BOOTLOADER_REGRESSION_FEATURE');

if (get_var('HDD_1')) {
    loadtest 'boot/boot_from_hdd';
}
else {
    loadtest "installation/bootloader_$vmm_family" if $vmm_family;
    if ($brf) {
        loadtest "regressions/$brf";
        return 1;
    }
    loadtest "installation/bootloader_$desktop";
    return 1 if get_var('INSTALLONLY');
    loadtest 'installation/firstboot';
    loadtest 'installation/zpool_rpool_setup';
}
load_featuretests;
loadtest 'shutdown/shutdown';

1;
# vim: set sw=4 et:
