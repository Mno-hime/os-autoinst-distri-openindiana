# OpenIndiana's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2017 SUSE LLC
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package openindianadistribution;
use base 'distribution';
use strict;

# Base class for all OpenIndiana tests

# don't import script_run - it will overwrite script_run from distribution and create a recursion
use testapi qw(send_key %cmd assert_screen check_screen check_var get_var
  match_has_tag set_var type_password type_string wait_idle wait_serial
  mouse_hide send_key_until_needlematch record_soft_failure
  wait_still_screen wait_screen_change assert_script_sudo);

sub handle_password_prompt {
    #assert_screen([qw(password-prompt no-password-prompt)]);
    if (check_screen('password-prompt', 2)) {
        type_password;
        send_key('ret');
    }
}

sub init() {
    my ($self) = @_;

    $self->SUPER::init();
    $self->init_consoles();
}

sub script_sudo($$) {
    my ($self, $prog, $wait) = @_;

    my $str = time;
    if ($wait > 0) {
        $prog = "$prog; echo $str-\$?- > /dev/$testapi::serialdev";
    }
    type_string "clear\n";    # poo#13710
    type_string "sudo $prog\n";
    handle_password_prompt;
    if ($wait > 0) {
        return wait_serial("$str-\\d+-");
    }
    return;
}

sub set_standard_prompt {
    my ($self, $user) = @_;
    $user ||= $testapi::username;
    if ($user eq 'root') {
        # set standard root prompt
        type_string "PS1='# '\n";
    }
    else {
        type_string "PS1='\$ '\n";
    }
}

sub x11_start_program($$$) {
    my ($self, $program, $timeout, $options) = @_;
    # enable valid option as default
    $options->{valid} //= 1;
    send_key "alt-f2";
    if (!check_screen("desktop-runner", $timeout)) {
        # if "desktop-runner" not found, send alt-f2 three times with 10 second timeout
        record_soft_failure 'alt-f2 did not made it for the first time...';
        send_key_until_needlematch 'desktop-runner', 'alt-f2', 3, 10;
    }
    type_string $program;
    wait_idle 5;
    if ($options->{terminal}) {
        send_key('alt-t');
        sleep 3;
    }
    send_key('ret');
    wait_still_screen unless $options->{no_wait};
}

# initialize the consoles needed during our tests
sub init_consoles {
    my ($self) = @_;

    if (get_var('VIRTUALIZATION')) {
        $self->add_console(
            'vnc',
            'vnc-base',
            {
                hostname => 'localhost',
                port     => get_var('VNC_INSTANCE', 0) + 11022
            });
    }
    if (check_var('BACKEND', 'svirt')) {
        my $hostname = get_var('VIRSH_GUEST');
        my $port = get_var('VIRSH_INSTANCE', 1) + 5900;
        $self->add_console(
            'sut',
            'vnc-base',
            {
                hostname => $hostname,
                port     => $port,
                depth    => check_var('VIRSH_VMM_FAMILY', 'virtualbox') ? 24 : undef,
                password => $testapi::password
            });
    }
    $self->add_console('root-console', 'tty-console', {tty => 2});
    $self->add_console('user-console', 'tty-console', {tty => 4});
    $self->add_console('x11',          'tty-console', {tty => 7});

    return;
}

sub become_root {
    my ($self) = @_;

    $self->script_sudo('bash', 0);
    type_string "echo \$LOGNAME > /dev/$testapi::serialdev\n";
    wait_serial("root", 10) || die "Root prompt not there";
    type_string "cd\n";
    $self->set_standard_prompt('root');
    type_string "clear\n";
}

# callback whenever a console is selected for the first time
sub activate_console {
    my ($self, $console) = @_;

    $console =~ m/^(\w+)-(console)/;
    my ($name, $user, $type) = ($1, $1, $2);
    $name = $user //= '';
    $type //= '';
    if ($name eq 'user') {
        $user = $testapi::username;
    }

    if ($type eq 'console') {
        my $nr = 4;
        $nr = 2 if ($name eq 'root');
        assert_screen("console$nr-selected");
        type_string "$testapi::username\n";
        handle_password_prompt;
        assert_screen "text-logged-in-user";
        $self->set_standard_prompt($testapi::username);
        if ($name eq 'root') {
            $self->become_root();
        }
    }
}

1;
# vim: set sw=4 et:
