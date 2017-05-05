# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package utils;

use base Exporter;
use Exporter;

use strict;

use testapi qw(is_serial_terminal :DEFAULT);

our @EXPORT = qw(
  clear_console
  reboot
  poweroff
  bootloader_dvd
  bootloader_hdd
  firstboot_setup
  mate_change_resolution_1024_768
  lightdm_login
  console_login
  wait_boot
  disable_fastreboot
  enable_vt
  activate_root_account
  pkg_call
  save_and_upload_log
  system_log_gathering
  deploy_kvm
);

# Function wrapping 'pkg' command with allowed return codes, timeout and logging facility.
# First parammeter is required command, all others are named and provided as hash
# for example:
#
#       pkg_call("update", exitcode => [0,102,103], log => "pkg.log");
#
# 'update': `pkg update` -- update system
# 'exitcode': allowed return code values
# 'log': capture log and store it in pkg.log

sub pkg_call {
    my $command = shift;
    my %args    = @_;
    # Exit status: '0': Command succeeded. '4': No changes were made - nothing to do.
    my $allow_exit_codes = $args{exitcode} || [0, 4];
    my $timeout          = $args{timeout}  || 700;
    my $log              = $args{log};
    my $sudo             = $args{sudo}     || 0;

    my $str = hashed_string("ZN$command");
    my $redirect = is_serial_terminal() ? '' : " > /dev/$serialdev";

    if ($log) {
        if ($sudo) {
            script_sudo("pkg $command | tee /tmp/$log ; echo $str-\${PIPESTATUS}-$redirect", 0);
        }
        else {
            script_run("pkg $command | tee /tmp/$log ; echo $str-\${PIPESTATUS}-$redirect", 0);
        }
    }
    else {
        if ($sudo) {
            script_sudo("pkg $command; echo $str-\$?-$redirect", 0);
        }
        else {
            script_run("pkg $command; echo $str-\$?-$redirect", 0);
        }
    }

    my $ret = wait_serial(qr/$str-\d+-/, $timeout);

    upload_logs("/tmp/$log") if $log;

    if ($ret) {
        my ($ret_code) = $ret =~ /$str-(\d+)/;
        die "'pkg $command' failed with code $ret_code" unless grep { $_ == $ret_code } @$allow_exit_codes;
        return $ret_code;
    }
    die 'pkg did not return an exitcode';
}

sub clear_console {
    type_string "clear\n";
}

sub reboot {
    my ($command) = @_;
    my $action = ($command eq 'poweroff') ? 'poweroff' : 'reboot';
    wait_idle;
    if (check_var('DESKTOP', 'mate')) {
        # we need to run the command out of terminal, otherwise it's not focused...
        x11_start_program('mate-session-save --shutdown-dialog', undef, {terminal => 1, no_wait => 1});
        assert_screen 'logoutdialog';
        if ($action eq 'poweroff') {
            send_key 'alt-s';    # shutdown
        }
        else {
            send_key 'alt-r';    # restart
        }
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        script_run "$action", 0;
    }
    reset_consoles;
}

sub poweroff {
    reboot('poweroff');
}

sub bootloader_dvd {
    if (check_var('DESKTOP', 'mate')) {
        assert_screen 'bootloader-menu-main-screen-media-boot';
        # Snapshots before 20161030 had GRUB bootloader,
        # which we don't want to test.
        unless (get_var('BUILD') >= 20161030) {
            send_key 'ret';
            return;
        }
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        assert_screen 'bootloader-menu-main-screen-media-boot-textmode';
    }
    send_key '5';
    assert_screen 'bootloader-menu-configuration';
    send_key '1';
    if (check_var('DESKTOP', 'mate')) {
        assert_screen 'bootloader-menu-main-screen-media-boot';
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        assert_screen 'bootloader-menu-main-screen-media-boot-textmode';
    }
    send_key 'ret';    # Boot
}

sub bootloader_hdd {
    assert_screen 'bootloader-menu-main-screen-installed-system';
    send_key 'ret';
    assert_screen 'boot-uname';
}

sub firstboot_setup {
    assert_screen 'boot-uname';
    assert_screen 'firstboot-keyboard', 180;
    send_key 'ret';
    assert_screen 'firstboot-language';
    send_key 'ret';
    assert_screen 'firstboot-language-en-set';
    assert_screen 'firstboot-configuring-devices';
}

sub mate_change_resolution_1024_768 {
    x11_start_program 'xrandr --output default --mode 1024x768';
    assert_screen 'mate-desktop';
    wait_still_screen;
}

sub lightdm_login {
    assert_screen 'lightdm', 280;
    wait_idle;
    type_string $testapi::username;
    send_key 'tab';
    type_password;
    send_key 'ret';
    # Sometimes the password did not make it for the first time
    for (1 .. 5) {
        if (check_screen('lightdm-incorrect-password', 5)) {
            record_soft_failure 'Typing password did not made it for the first time...';
            type_password;
            send_key 'ret';
        }
        else {
            last;
        }
    }
}

sub console_login {
    assert_screen 'console-login', 300;
    type_string "$testapi::username\n";
    assert_screen 'console-login-password';
    type_password;
    send_key 'ret';
}

sub wait_boot {
    my ($args) = @_;
    # Snapshot 20160421 does fast reboot w/o BIOS in place.
    if (check_screen('sea-bios-splash', 120)) {
        assert_screen 'bootloader-menu-main-screen-installed-system';
        send_key 'ret';
        assert_screen 'boot-uname' if get_var('BUILD') >= 20161030;
    }
    if (check_var('DESKTOP', 'mate')) {
        lightdm_login;
        assert_screen 'mate-desktop';
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        console_login;
    }
    wait_idle;
}

sub activate_root_account {
    assert_script_run 'su - root';
    type_password;
    send_key 'ret';
    type_password;
    send_key 'ret';
    type_password;
    send_key 'ret';
}

sub disable_fastreboot {
    assert_script_sudo 'svcprop -p config/fastreboot_default svc:/system/boot-config:default';
    assert_script_sudo '/usr/sbin/svccfg -s system/boot-config:default setprop config/fastreboot_default=false';
    assert_script_sudo '/usr/sbin/svcadm refresh svc:/system/boot-config:default';
    assert_script_sudo 'svcprop -p config/fastreboot_default svc:/system/boot-config:default';
}

sub enable_vt {
    # Enable virtual consoles 2 and 4
    assert_script_run 'svcs vtdaemon';
    assert_script_run 'svcs console-login';
    assert_script_sudo '/usr/sbin/svcadm enable vtdaemon';
    assert_script_sudo '/usr/sbin/svcadm enable console-login:vt2';
    assert_script_sudo '/usr/sbin/svcadm enable console-login:vt4';
    # Disable automatic VT screen locking
    assert_script_sudo '/usr/sbin/svccfg -s vtdaemon setprop options/secure=false';
    assert_script_sudo '/usr/sbin/svccfg -s vtdaemon setprop options/hotkeys=true';
    assert_script_sudo '/usr/sbin/svcadm refresh vtdaemon';
    assert_script_sudo '/usr/sbin/svcadm restart vtdaemon';
    assert_script_run 'svcs vtdaemon';
    assert_script_run 'svcs console-login';
    disable_fastreboot;
}

# Save command's output and upload it
sub save_and_upload_log {
    my ($cmd, $file, $args) = @_;
    script_run("$cmd | tee $file", $args->{timeout});
    upload_logs($file) unless $args->{noupload};
    save_screenshot if $args->{screenshot};
}

sub system_log_gathering {
    my $self = shift;
    save_and_upload_log('dmesg',    'dmesg.txt');
    save_and_upload_log('svcs -xv', 'failed_services.txt');
    assert_script_run('tar cfJ svc_logs.txz /var/svc/log/');
    upload_logs('svc_logs.txz');
    if (check_var('DESKTOP', 'mate')) {
        upload_logs("/home/$testapi::username/.xsession-errors", failok => 1);
        upload_logs('/var/log/Xorg.0.log');
        upload_logs('/var/adm/messages');
    }
}

sub deploy_kvm {
    my ($image) = @_;

    # Install kvm kernel module and QEMU device emulator
    pkg_call('install driver/i86pc/kvm system/qemu/kvm', sudo => 1);
    # Test module load
    assert_script_sudo('modload /usr/kernel/drv/amd64/kvm');
    assert_script_sudo('modinfo | grep kvm');
    assert_script_sudo('test -c /dev/kvm');

    # Get Alpine Linux virt ISO to test in illumos KVM
    assert_script_run 'wget ' . data_url("virtualization/$image");
    my $phys_link = script_output('dladm show-phys -p -o LINK');

    # Create virtual NIC 'vnic0' bound to $phys_link link
    script_sudo('dladm delete-vnic vnic0');
    assert_script_sudo("dladm create-vnic -l $phys_link vnic0");
}

1;
