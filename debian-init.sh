#!/bin/bash

function sources-backports {
    if [ ! -f /etc/apt/sources.list.d/backports.list ]
    then
	echo "deb http://ftp.uk.debian.org/debian jessie-backports main contrib" > /etc/apt/sources.list.d/backports.list
	apt update
    fi
}

function sources-docker {
    if [ ! -f /etc/apt/sources.list.d/docker.list ]
    then
	apt install -y apt-transport-https
	echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
	wget -O - "https://apt.dockerproject.org/gpg" | apt-key add -
	apt update
    fi
}

function system-upgrade {
    read -p "Upgrade the system? [y/N]" system_upgrade
    case $system_upgrade in
	[yY])
	    echo "Upgrading Debian install..."
	    apt update
	    apt upgrade -y
	    ;;
	*)
	    echo "Skipping upgrading Debian install"
	    ;;
    esac
}

function system-reboot {
    read -p "Reboot now? [Y/n]" system_reboot
    case $system_reboot in
	[nN])
	    echo "Skipping reboot"
	    ;;
	*)
	    echo "Rebooting..."
	    reboot
	    ;;
    esac
}

function system-cleanup {
    apt-get autoremove -y
    apt-get autoclean -y
    system-reboot
}

function install-grsec {
    read -p "Install grsecurity kernel patches? [y/N]" grsec
    case $grsec in
	[yY])
	    echo "Installing grsecurity kernel patches..."
	    sources-backports
	    apt install -y -t jessie-backports linux-image-grsec-amd64
	    echo "Finished installing grsecurity patched kernel!"
	    system-reboot
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
	    sources-backports
	    apt install -y -t jessie-backports linux-headers-$(uname -r)
	    apt install -y -t jessie-backports zfs-dkms zfs-initramfs
	    apt install -y nfs-kernel-server samba
	    echo "Finnished installing ZFS tools & kernel modules!"
	    system-reboot
	    ;;
	*)
	    echo "Skipping ZFS tools & kernel modules"
	    ;;
    esac
}

function install-kvm {
    read -p "Install KVM packages? [y/N]" kvm
    case $kvm in
	[yY])
	    echo "Installing KVM packages..."
	    apt install -y qemu-kvm libvirt-bin virtinst
	    echo "Check that virtualization support is enabled in BIOS!"
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

function install-extra {
    read -p "Install extra packages? [y/N]" extra
    case $extra in
	[yY])
	    echo "Installing extra packages..."
	    apt install -y xz-utils
	    ;;
	*)
	    echo "Skipping extra packages"
	    ;;
    esac
}

system-upgrade
install-grsec
install-zfs
install-kvm
install-docker
install-extra
system-cleanup
