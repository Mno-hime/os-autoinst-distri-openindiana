# OpenIndiana's openQA tests
#
# Copyright © 2017 Michal Nowak
# Copyright © 2017 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

package utils;

use base Exporter;
use Exporter;

use strict;

use testapi qw(assert_shutdown :DEFAULT);

our @EXPORT = qw(
  clear_console
  clear_and_verify_console
  pre_bootmenu_setup
  bootloader_dvd
  bootloader_hdd
  firstboot_setup
  mate_change_resolution
  mate_set_resolution_1024_768
  match_mate_desktop
  lightdm_login
  console_login
  assert_mate
  wait_boot
  disable_fastreboot
  enable_vt
  activate_root_account
  pkg_call
  save_and_upload_log
  system_log_gathering
  core_files_gathering
  deploy_kvm
  assert_shutdown_and_restore_system
  power_action
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

    my $str      = hashed_string("ZN$command");
    my $redirect = " > /dev/$serialdev";

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

sub clear_and_verify_console {
    type_string "clear\n";
    assert_screen('cleared-console');
}

sub pre_bootmenu_setup {
    if (get_var('USBBOOT')) {
        assert_screen 'sea-bios-splash', 5;
        send_key 'esc';
        assert_screen 'boot-menu-usb', 4;
        send_key(2 + get_var('NUMDISKS'));
    }
}

sub bootloader_dvd {
    if (check_var('DESKTOP', 'mate')) {
        assert_screen 'bootloader-menu-main-screen-media-boot', 90;
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        assert_screen 'bootloader-menu-main-screen-media-boot-textmode', 90;
    }
    if (get_var('SSH_IN_LIVE_ENVIRONMENT')) {
        send_key '7';
        assert_screen 'bootloader-menu-oi-extras';
        send_key '4';
        assert_screen 'bootloader-menu-oi-extras-ssh-enabled';
        send_key '1';
        assert_screen 'bootloader-menu-main-screen-media-boot';
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
    assert_screen 'boot-uname', 90;
    # Firstboot configuration is not being asked for when SSH is on
    unless (get_var('SSH_IN_LIVE_ENVIRONMENT')) {
        if (check_var('DESKTOP', 'textmode') || get_var('BUILD') < 20171031) {
            assert_screen 'firstboot-keyboard', 180;
            send_key 'ret';
        }
        assert_screen 'firstboot-language', 180;
        send_key 'ret';
        assert_screen 'firstboot-language-en-set';
    }
    assert_screen 'firstboot-configuring-devices', get_var('SSH_IN_LIVE_ENVIRONMENT') ? 200 : undef;
}

sub mate_change_resolution {
    my $output = check_var('VIRSH_VMM_FAMILY', 'virtualbox') ? 'VGA-0' : 'default';
    x11_start_program "xrandr --output $output --mode 1024x768";
    assert_screen 'mate-desktop';
    wait_still_screen;
}

sub lightdm_login {
    assert_screen 'lightdm', 280;
    mouse_hide;
    wait_idle;
    type_string $testapi::username;
    send_key 'tab';
    type_password;
    send_key 'ret';
    # Sometimes the password did not make it for the first time
    for (1 .. 5) {
        if (check_screen('lightdm-incorrect-password', 5)) {
            record_soft_failure 'Typing password did not made it';
            type_password;
            send_key 'ret';
        }
        else {
            return;
        }
    }
    die "Can't login via LightDM to MATE";
}

sub console_login {
    assert_screen 'console-login', 300;
    type_string "$testapi::username\n";
    assert_screen 'console-login-password';
    type_password;
    send_key 'ret';
}

sub mate_set_resolution_1024_768 {
    # Make 1024x768 resolution permanent
    x11_start_program 'mate-display-properties';
    send_key 'alt-tab';    # Workaround: Pop-up the window
    assert_screen 'mate-display-properties';
    send_key 'alt-r';
    send_key 'end';
    send_key_until_needlematch('mate-display-properties-1024-768', 'up', 5);
    send_key 'alt-a';
    assert_and_click('display-looks-ok-buton', 'left', 10, 2);
    assert_screen 'mate-display-properties';
    send_key 'alt-c';
}

sub match_mate_desktop {
    unless (check_screen('mate-desktop', 200)) {
        if (check_screen 'mate-desktop-missing-icons') {
            record_soft_failure "illumos#8118, mate-desktop/caja#792: caja won't show desktop icons: "
              . "g_hash_table_foreach: assertion 'version == hash_table->version' failed";
            x11_start_program 'caja --quit';
        }
        else {
            die "Can't match MATE desktop";
        }
    }
    if (check_screen('panel-object-quit-unexpectedly', 5)) {
        send_key 'ret';
        wait_still_screen;
    }
}

# For releases before and including 20161030 OI can't use cirrus driver on QEMU
# and therefor boots to 1280x768 px resolution, similarly VirtualBox after build
# 20171111 has vboxvideo X11 driver, and defaults to 800x600, but we need to
# get to 1024x768 somehow.
sub assert_mate {
    if (check_var('BACKEND', 'qemu') && !check_var('QEMUVGA', 'cirrus')) {
        assert_screen 'mate-desktop-1280x768', 200;
        wait_still_screen;
        mate_change_resolution;
        mate_set_resolution_1024_768;
    }
    elsif (check_var('VIRSH_VMM_FAMILY', 'virtualbox') && get_var('BUILD') >= 20171111) {
        assert_screen 'mate-desktop-800x600', 200;
        wait_still_screen;
        mate_change_resolution;
        mate_set_resolution_1024_768;
    }
    else {
        wait_still_screen;
    }
    match_mate_desktop;
}

sub wait_boot {
    my ($self) = @_;
    # Snapshot 20160421 does fast reboot w/o BIOS in place.
    if (check_screen([qw(sea-bios-splash vbox-select-boot-device)], 200)) {
        assert_screen('bootloader-menu-main-screen-installed-system', 90);
        send_key 'ret';
        if (get_var('BUILD') >= 20161030) {
            assert_screen 'boot-uname', check_var('VIRSH_VMM_FAMILY', 'xen') ? 90 : 30;
        }
    }
    if (check_var('DESKTOP', 'mate')) {
        lightdm_login;
        assert_mate;
        match_mate_desktop;
    }
    elsif (check_var('DESKTOP', 'textmode')) {
        assert_screen 'console-login', 300;
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
    # Enable virtual console 4
    assert_script_run 'svcs vtdaemon';
    assert_script_run 'svcs console-login';
    assert_script_sudo '/usr/sbin/svcadm enable vtdaemon';
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

sub core_files_gathering {
    my %args = @_;
    $args{nosudo} ||= 0;
    my $sudo = $args{nosudo} ? '' : 'sudo';
    # Make sure `find`'s non-zero exit code won't kill the process
    my $cores = script_output "$sudo find /home/ /root/ /var/ /tmp/ -type f -name 'core.[0-9]*' | tr -s '\n' ' '";
    my @cores = split / /, $cores;
    foreach my $core (@cores) {
        save_and_upload_log("$sudo pmap $core",   "$core.pmap");
        save_and_upload_log("$sudo pstack $core", "$core.pstack");
        script_run("$sudo xz -v $core");
        upload_logs("$sudo core.xz", failok => 1);
        my $title  = script_output "$sudo awk '/core/ {print \$NF}' $core.pstack" . '.core';
        my $output = script_output "$sudo cat $core.pstack";
        record_info($title, $output, result => 'softfail');
    }
}

sub system_log_gathering {
    return if check_var('VIRSH_VMM_FAMILY', 'xen');    # no network
    my %args = @_;
    $args{nosudo} ||= 0;
    my $sudo = $args{nosudo} ? '' : 'sudo';
    core_files_gathering(nosudo => $args{nosudo});
    script_run('curl -O ' . data_url('utils/system_log_gathering.sh'));
    script_run("bash system_log_gathering.sh $sudo");
    upload_logs('system_log_gathering.txz', failok => 1);
    script_run('rm -rf system_log_gathering.*');
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

# VNC connection to SUT (the 'sut' console) is terminated on Xen via svirt
# backend and we have to re-connect *after* the restart, otherwise we end up
# with stalled VNC connection. The tricky part is to know *when* the system
# is already booting.
sub assert_shutdown_and_restore_system {
    my ($action) = @_;
    $action //= 'reboot';
    my $vnc_console = 'sut';
    console($vnc_console)->disable_vnc_stalls;
    assert_shutdown(90);
    if ($action eq 'reboot') {
        reset_consoles;
        console('svirt')->define_and_start;
        select_console($vnc_console);
    }
}

=head2 power_action

    power_action($action);

Executes power action (e.g. poweroff, reboot) from root console.
=cut
sub power_action {
    my $action = shift;
    my %args   = @_;
    die "'action' was not provided" unless $action;
    console('sut')->disable_vnc_stalls if check_var('BACKEND', 'svirt');
    if ($action eq 'poweroff') {
        power('acpi');
    }
    elsif ($action eq 'reboot') {
        if (check_var('DESKTOP', 'mate')) {
            select_console 'x11';
            x11_start_program('mate-session-save --shutdown-dialog', undef, {terminal => 0, no_wait => 1});
            assert_screen 'logoutdialog', 90;
            send_key 'alt-r';
            if (check_screen('mate-program-still-running', 5)) {
                record_soft_failure 'Some program is still running';
                assert_and_click('shut-down-anyway', 'left', 10, 2);
            }
        }
        elsif (check_var('DESKTOP', 'textmode')) {
            my $sudo = $args{nosudo} ? '' : 'sudo';
            type_string "$sudo $action\n";
        }
    }
    else {
        die "Action '$action' not implemented";
    }
    if (check_var('VIRSH_VMM_FAMILY', 'xen')) {
        assert_shutdown_and_restore_system($action);
    }
    else {
        my $timeout = 60;
        diag "Sleep for $timeout seconds";
        sleep($timeout) if $action eq 'poweroff';
    }
    reset_consoles;
}

1;
