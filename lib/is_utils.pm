# OpenIndiana's openQA tests
#
# Copyright © 2018 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package is_utils;

use base Exporter;
use Exporter;

use strict;

use testapi qw(check_var :DEFAULT);

our @EXPORT = qw(
  is_minimal
);

sub is_minimal {
    return check_var('FLAVOR', 'MinimalUSB') || check_var('FLAVOR', 'Minimal');
}

1;
