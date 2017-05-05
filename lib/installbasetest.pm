# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package installbasetest;
use base 'openindianabasetest';
use strict;

# All steps in the installation are 'fatal'.
sub test_flags() {
    return {fatal => 1};
}

1;
# vim: set sw=4 et:
