# OpenIndiana's openQA tests
#
# Copyright © 2016 SUSE LLC
# Copyright © 2017 Michal Nowak <mnowak@startmail.com>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Xen libvirt domains need to be redefined after installation
#          to restart properly
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'installbasetest';
use strict;
use testapi;

sub run() {
    my $svirt = console('svirt');
    $svirt->define_and_start;
    # On svirt backend we need to re-connect to 'sut' console which got
    # unusable after post-install shutdown. reset_consoles() makes
    # re-connect with credentials to 'sut' console possible.
    select_console 'sut';
}

1;
