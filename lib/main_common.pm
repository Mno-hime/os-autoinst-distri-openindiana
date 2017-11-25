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
use testapi;
use autotest;
use strict;
use warnings;

our @EXPORT = qw(
  $live_user_name
  $live_user_password
  $live_root_password
  init_main
  loadtest
  set_defaults_for_username_and_password
);

# Live medium's credentials
our $live_user_name     = 'jack';
our $live_user_password = 'jack';
our $live_root_password = 'openindiana';

sub set_defaults_for_username_and_password {
    # Installed system's credentials
    $testapi::username = 'robot';
    $testapi::password = 'nots3cr3t';
    $testapi::realname = 'Karel Capek';
}

sub init_main {
    set_defaults_for_username_and_password();
}

sub loadtest {
    my ($test) = @_;
    autotest::loadtest("tests/$test.pm");
}

1;
