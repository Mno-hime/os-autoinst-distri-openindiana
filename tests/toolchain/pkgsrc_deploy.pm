# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Deploy Joyent's pkgsrc (https://pkgsrc.joyent.com/install-on-illumos/)
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run() {
    select_console 'user-console';

    pkg_call('install gnupg', sudo => 1);    # gpg2 binary

    # Copy and paste the lines below to install the 64-bit set.
    assert_script_run 'BOOTSTRAP_TAR="bootstrap-2017Q3-x86_64.tar.gz"';
    assert_script_run 'BOOTSTRAP_SHA="10bb81b100e03791a976fb61f15f7ff95cad4930"';

    # Download the bootstrap kit to the current directory.
    assert_script_run 'curl -O https://pkgsrc.joyent.com/packages/SmartOS/bootstrap/${BOOTSTRAP_TAR}';

    # Verify the SHA1 checksum.
    assert_script_run '[ "${BOOTSTRAP_SHA}" = "$(/bin/digest -a sha1 ${BOOTSTRAP_TAR})" ]';

    # Verify PGP signature.  This step is optional, and requires gpg2.
    assert_script_run 'curl -O https://pkgsrc.joyent.com/packages/SmartOS/bootstrap/${BOOTSTRAP_TAR}.asc';
    assert_script_run 'curl -sS https://pkgsrc.joyent.com/pgp/DE817B8E.asc | gpg2 --import';
    assert_script_run 'gpg2 --verify ${BOOTSTRAP_TAR}{.asc,}';

    # Install bootstrap kit to /opt/local
    assert_script_sudo 'tar -zxpf ${BOOTSTRAP_TAR} -C /';

    # Add to PATH/MANPATH.
    assert_script_run 'PATH=/opt/local/sbin:/opt/local/bin:$PATH';
    assert_script_run 'MANPATH=/opt/local/man:$MANPATH';
}

1;
