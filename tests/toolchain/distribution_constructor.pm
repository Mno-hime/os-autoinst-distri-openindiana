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

sub run() {
    select_console 'user-console';
    pkg_call('install distribution-constructor wget', sudo => 1);

    my $snapdate = localtime->strftime('%Y%m%d');
    my $variant  = get_required_var('DC_VARIANT');
    my $name     = "slim_${variant}_X86.xml";
    assert_script_run 'wget ' . data_url("toolchain/$name");

    # Build image
    assert_script_sudo("distro_const build $name", 9000);

    # Upload logs from construction
    my $dc_root = "/rpool/dc";
    assert_script_run "cp `ls -t ${dc_root}/logs/simple-log-* | head -n1` simple-log-$variant.txt";
    assert_script_run "cp `ls -t ${dc_root}/logs/detail-log-* | head -n1` detail-log-$variant.txt";
    upload_logs "simple-log-$variant.txt";
    upload_logs "detail-log-$variant.txt";

    # Upload constructed ISO and USB media as public assets
    script_run "ls -lh ${dc_root}/media/";
    for my $medium ('iso', 'usb') {
        my $upload_filename = "OI-hipster-$variant-$snapdate.$medium";
        assert_script_sudo "mv ${dc_root}/media/OpenIndiana_${variant}_X86.$medium ${dc_root}/media/$upload_filename";
        for (1 .. 5) {    # Try to upload image up to five times
            last unless (upload_asset("${dc_root}/media/$upload_filename", 1, 0, 300));
        }
        record_info("$variant$medium", "$upload_filename uploaded successfully");
        # Save some space on openQA worker as OS image takes 40-45 GB
        assert_script_sudo "rm -f ${dc_root}/media/$upload_filename";
    }
    type_string "df -h > /dev/$testapi::serialdev\n";
}

1;

# vim: set sw=4 et:
