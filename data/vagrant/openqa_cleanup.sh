#!/bin/bash -eux

# `userdel $testapi::username` is in "shutdown/shutdown" test
sed -i -e 's/TZ=.*/TZ=UTC/' /etc/default/init
grep ^TZ=UTC /etc/default/init
/usr/bin/hostname openindiana
/usr/bin/hostname