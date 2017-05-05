# OpenIndiana's openQA tests
#
# Copyright © 2012-2016 SUSE LLC
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Base class for all OpenIndiana console tests

package consoletest;
use base 'openindianabasetest';
use strict;
use testapi;
use utils 'system_log_gathering';

sub post_run_hook {
    my ($self) = @_;

    if (!check_var('DESKTOP', 'mate')) {
        # start next test in home directory
        type_string "cd\n";
        # clear screen to make screen content ready for next test
        $self->clear_and_verify_console;
    }
}

# All steps in the installation are 'important'.
sub test_flags {
    return {important => 1};
}

sub post_fail_hook {
    $testapi::serialdev = get_var('SERIALDEV', 'ttya');
    system_log_gathering;
}

1;
# vim: set sw=4 et:
