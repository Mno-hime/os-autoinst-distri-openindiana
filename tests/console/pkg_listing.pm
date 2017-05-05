# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: listing package information
# Maintainer: Michal Nowak <mnowak@startmail.com>

use base 'consoletest';
use strict;
use testapi;
use utils 'pkg_call';

sub run() {
    select_console 'root-console';

    pkg_call('list bash');
    pkg_call('info dash', exitcode => [1]);
    pkg_call('info -r dash');
    pkg_call('contents dash', exitcode => [1]);
    pkg_call('contents -r dash');
    pkg_call('contents -r -t depend -o fmri dash');
}

1;

# vim: set sw=4 et:
