# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Build OpenIndiana Text and Live USB and ISO media
#   https://wiki.openindiana.org/oi/Distribution+Constructor
#   https://docs.oracle.com/cd/E23824_01/html/E21800/
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';
use Time::Piece;

sub run {
    select_console 'user-console';

    pkg_call('install distribution-constructor wget', sudo => 1);

    my $snapdate      = localtime->strftime('%Y%m%d');
    my $variant       = get_required_var('DC_OS_VARIANT');
    my $media_variant = get_required_var('DC_MEDIA_VARIANT');
    my $name          = "OpenIndiana_${variant}_X86.xml";
    assert_script_run 'wget ' . data_url("distribution_constructor/$name");

    # Build image
    assert_script_sudo("distro_const build $name", 9000);

    # Upload logs from construction
    my $dc_root = '/rpool/dc';
    for my $log_type ('simple', 'detail') {
        my $log_type_txt = "$log_type-log-$variant.txt";
        assert_script_run "cp `ls -t $dc_root/logs/$log_type-log-* | head -n1` $log_type_txt";
        upload_logs $log_type_txt;
    }

    # Upload constructed ISO and USB media as public assets
    assert_script_run "ls -lh $dc_root/media/";
    for my $medium ('iso', 'usb') {
        my $upload_filename      = "OI-hipster-$media_variant-$snapdate.$medium";
        my $upload_filename_path = "$dc_root/media/$upload_filename";
        assert_script_sudo "mv $dc_root/media/OpenIndiana_${variant}_X86.$medium $upload_filename_path";
        for (1 .. 5) {    # Try to upload image up to five times
            last unless upload_asset($upload_filename_path, 1, 0, 600);
        }
        record_info("$variant$medium", "$upload_filename uploaded successfully");
        # Save some space on openQA worker as OS image takes 40-45 GB
        assert_script_sudo "rm -f $upload_filename_path";
    }
    script_run "df -h > /dev/$testapi::serialdev", 0;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
