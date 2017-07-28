#!/bin/sh

set -o nounset
set -o errexit

build="$1"
shift
if [[ "$*" ]]; then
    dcbuild="$1"
    shift
else
    dcbuild=""
fi
echo "BUILD=$build"
filter="$*"
client="/usr/share/openqa/script/client"
#client=echo
asset_root=/var/lib/openqa/share/factory
if [[ "${dcbuild}" ]]; then
    $client isos post hdd=openindiana-hipster-x86_64-${build}-Server@64bit.qcow2 DISTRI=openindiana-dcbuild VERSION=hipster FLAVOR=dcbuild ARCH=x86_64 BUILD=$build
else
    for medium in iso usb; do
        for flavor in Minimal Server Live; do
            if [ "$medium" = "usb" ]; then flavor=${flavor}USB; fi
            for arch in x86_64 i386; do
                if [[ "$flavor" =~ "Live" && "$arch" = "i386" ]]; then continue; fi
                if [[ "$flavor" =~ "Minimal" ]]; then mediumtype="minimal"; fi
                if [[ "$flavor" =~ "Server" ]]; then mediumtype="text"; fi
                if [[ "$flavor" =~ "Live" ]]; then mediumtype="gui"; fi
                if [[ "$medium" = "usb" ]]; then
                    mediumpath="../other/"
                    mediumpathreal='other'
                else
                    mediumpath=""
                    mediumpathreal='iso'
                fi
                filepath="${asset_root}/${mediumpathreal}/OI-hipster-${mediumtype}-${build}.${medium}"
                if [ ! -f ${filepath} ]; then continue; fi
                echo -ne "  $flavor\t$arch\t$medium\t"
                $client isos post iso=${mediumpath}OI-hipster-${mediumtype}-${build}.${medium} DISTRI=openindiana VERSION=hipster FLAVOR=$flavor ARCH=$arch BUILD=$build "$filter"
            done
        done
    done
fi