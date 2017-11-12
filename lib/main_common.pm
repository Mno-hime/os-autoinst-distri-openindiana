# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package main_common;
use base Exporter;
use Exporter;
use testapi qw(check_var get_var set_var diag);
use autotest;
use strict;
use warnings;

our @EXPORT = qw(
  init_main
  loadtest
  set_defaults_for_username_and_password
);

sub init_main {
    set_defaults_for_username_and_password();
}

sub loadtest {
    my ($test) = @_;
    autotest::loadtest("tests/$test.pm");
}

sub set_defaults_for_username_and_password {
    # Installed system's credentials
    $testapi::username = 'robot';
    $testapi::password = 'nots3cr3t';
    $testapi::realname = 'Karel Capek';

    # Live medium's credentials
    $testapi::live_user_name     = 'jack';
    $testapi::live_user_password = 'jack';
    $testapi::live_root_password = 'openindiana';
}

1;
