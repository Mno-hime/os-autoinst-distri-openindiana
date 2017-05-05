# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Base class for all OpenIndiana tests

package openindianabasetest;
use base 'basetest';

use testapi;
use strict;
use utils;

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);
    $self->{in_wait_boot} = 0;
    return $self;
}

# Additional to backend testapi 'clear-console' we do a needle match to ensure
# continuation only after verification
sub clear_and_verify_console {
    my ($self) = @_;

    clear_console;
    assert_screen('cleared-console');
}

# Set a simple reproducible prompt for easier needle matching without hostname
sub set_standard_prompt {
    $testapi::distri->set_standard_prompt;
}

1;

# vim: set sw=4 et:
