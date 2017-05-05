#!/bin/bash

sudo=$1

mkdir system_log_gathering
pushd system_log_gathering
$sudo prtconf -v > prtconf-v.txt
$sudo dmesg > dmesg.txt
$sudo svcs -xv > failed_services.txt
$sudo locale > locale_root.txt
locale > locale_user.txt            # Never with `sudo`
$sudo cp -R /var/svc/log/ var_svc_log
$sudo cp /var/adm/messages .
# MATE specific
$sudo cp /etc/sudoers .
$sudo cp $HOME/.xsession-errors user_xsession-errors
$sudo cp /jack/.xsession-errors jack_xsession-errors
$sudo cp /var/log/Xorg.0.log .
popd
$sudo tar cfJ system_log_gathering.txz system_log_gathering
$sudo rm -rf system_log_gathering