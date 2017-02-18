#!/bin/bash

function sources-backports {
    echo "deb http://ftp.debian.org/debian jessie-backports main contrib" > /etc/apt/sources.list.d/backports.list
    apt update
}

function sources-docker {
    echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
    wget -O - "https://apt.dockerproject.org/gpg" | apt-key add -
    apt install -y apt-transport-https
    apt update
}

function install-grsec {
    #Switch to Grsec kernel
    apt install -y -t jessie-backports linux-image-grsec-amd64
}

function install-zfs {
    #ZFS
    apt install -y -t jessie-backports linux-headers-$(uname -r)
    apt install -y -t jessie-backports zfs-dkms zfs-initramfs
}

function install-kvm {
    #KVM
    apt install -y qemu-kvm libvirt-bin virtinst
}

function install-docker {
    apt install -y docker-engine
}

sources-backports
install-grsec
install-zfs
install-kvm

sources-docker
install-docker
