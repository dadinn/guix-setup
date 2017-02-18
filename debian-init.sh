#!/bin/bash

function sources-backports {
    echo "deb http://ftp.uk.debian.org/debian jessie-backports main contrib" > /etc/apt/sources.list.d/backports.list
    apt update
}

function sources-docker {
    echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
    wget -O - "https://apt.dockerproject.org/gpg" | apt-key add -
    apt install -y apt-transport-https
    apt update
}

function install-grsec {
    read -p "Install grsecurity kernel patches? [y/N]" grsec
    case $grsec in
	[yY])
	    echo "Installing grsecurity kernel patches..."
	    apt install -y -t jessie-backports linux-image-grsec-amd64
	    ;;
	*)
	    echo "Skipping grsecurity kernel patches"
	    ;;
    esac
}

function install-zfs {
    read -p "Install ZFS tools & kernel modules? [y/N]" zfs
    case $zfs in
	[yY])
	    echo "Installing ZFS tools & kernel modules..."
	    apt install -y -t jessie-backports linux-headers-$(uname -r)
	    ;;
	*)
	    echo "Skipping ZFS tools & kernel modules"
	    apt install -y -t jessie-backports zfs-dkms zfs-initramfs
	    ;;
    esac
}

function install-kvm {
    read -p "Install KVM packages? [y/N]" kvm
    case $kvm in
	[yY])
	    echo "Installing KVM packages..."
	    apt install -y qemu-kvm libvirt-bin virtinst
	    ;;
	*)
	    echo "Skipping KVM packages"
	    ;;
    esac
}

function install-docker {
    read -p "Install Docker Engine? [y/N]" docker
    case $docker in
	[yY])
	    echo "Installing Docker Engine..."
	    sources-docker
	    apt install -y docker-engine
	    ;;
	*)
	    echo "Skipping Docker Engine"
	    ;;
    esac
}

sources-backports
install-grsec
install-zfs
install-kvm
install-docker
