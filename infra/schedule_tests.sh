#!/bin/bash

set -o nounset
set -o errexit

build="$1"
shift
if [[ "$*" =~ 'dcbuild' ]]; then
    dcbuild="$1"
    shift
else
    dcbuild=''
fi
if [[ "$*" ]]; then
    flavors="$1"
    shift
else
    flavors='Minimal Server Live'
fi
echo "Scheduling build $build"
filter="$*"
client='/usr/share/openqa/script/client'
#client=echo
asset_root=/var/lib/openqa/share/factory
products=0
if [[ "${dcbuild}" ]]; then
    $client isos post hdd="openindiana-hipster-x86_64-${build}-Server@64bit.qcow2" DISTRI=openindiana-dcbuild VERSION=hipster FLAVOR=dcbuild ARCH=x86_64 BUILD="$build" "$filter" && ((++products))
else
    for medium in iso usb; do
        for flavor in $flavors; do
            if [ "$medium" = 'usb' ]; then flavor=${flavor}USB; fi
            arch='x86_64'
            mediumtype=''
            if [[ "$flavor" = 'Minimal' || "$flavor" = 'MinimalUSB' ]]; then mediumtype='minimal'; fi
            if [[ "$flavor" = 'Server' || "$flavor" = 'ServerUSB' ]]; then mediumtype='text'; fi
            if [[ "$flavor" = 'Live' || "$flavor" = 'LiveUSB' ]]; then mediumtype='gui'; fi
            if [[ -z "$mediumtype" ]]; then break; fi
            if [[ "$medium" = 'usb' ]] || [[ "$medium" = 'iso' ]]; then
                mediumpathreal='iso'
            fi
            filepath="${asset_root}/${mediumpathreal}/OI-hipster-${mediumtype}-${build}.${medium}"
            if [ ! -f "${filepath}" ]; then
                filepath="${filepath/OI/fixed/OI}"
                if [ ! -f "${filepath}" ]; then
                    continue;
                fi
            fi
            echo -ne "  $flavor\t$arch\t$medium\t"
            $client isos post iso="OI-hipster-${mediumtype}-${build}.${medium}" DISTRI=openindiana VERSION=hipster FLAVOR="$flavor" ARCH=$arch BUILD="$build" "$filter" && ((++products))
        done
    done
fi
echo "Scheduled $products products"
