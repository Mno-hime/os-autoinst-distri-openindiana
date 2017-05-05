# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Make sure current OpenIndiana is able to build oi-userland
#   based on https://wiki.openindiana.org/oi/Building+with+oi-userland
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils qw(pkg_call);

sub run() {
    select_console 'user-console';

    # Install toolchain required for building OI-userland
    pkg_call('install build-essential', sudo => 1, exitcode => [0, 4]);

    # Prepare sources
    assert_script_run('git clone https://github.com/OpenIndiana/oi-userland.git');
    assert_script_run('pushd oi-userland');
    assert_script_run('gmake setup');

    # Setup local repository
    pkg_call('set-publisher -p file://$HOME/oi-userland/i386/repo', sudo => 1);
    pkg_call('set-publisher -P userland',                           sudo => 1);
    pkg_call('publisher | grep userland');
    pkg_call('set-publisher --non-sticky openindiana.org', sudo => 1);
    pkg_call('publisher | grep openindiana\.org.*non-sticky');

    # Build & publish package to local repository
    assert_script_run('pushd components/shell/parallel/');
    assert_script_sudo('gmake env-prep', 200);
    assert_script_run('gmake publish', 600);

    # Make sure package was install from userland repository
    pkg_call('change-facet facet.version-lock.shell/parallel=false', sudo => 1);
    pkg_call('install parallel',                                     sudo => 1);
    pkg_call('info parallel');
    pkg_call('info parallel | grep userland');

    # Verify GNU Parallel actually works
    assert_script_run('ls ~/.bash* | parallel file {} 2> /dev/null');

    assert_script_run('popd');
    assert_script_run('popd');
    assert_script_run('rm -rf oi-userland');

    # Clean the mess
    pkg_call('uninstall parallel',                                  sudo     => 1);
    pkg_call('info parallel',                                       exitcode => [1]);
    pkg_call('unset-publisher userland',                            sudo     => 1);
    pkg_call('change-facet facet.version-lock.shell/parallel=true', sudo     => 1);
    pkg_call('set-publisher --sticky openindiana.org',              sudo     => 1);
}

1;

# vim: set sw=4 et:
