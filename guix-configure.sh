#!/bin/bash

source guix-defaults.sh

### GUIX CONFIGURATION

root_profile=/var/guix/profiles/per-user/root/guix-profile

echo "Adding info pages..."

if [ ! -d /usr/local/share/info ]
then
    mkdir /usr/local/share/info
fi

for i in $root_profile/share/info/*
do
    if [ ! -L /usr/local/share/info/$(basename $i) ]
    then
	ln -s $i /usr/local/share/info/
    fi
done

echo "Configuring PATH for root user"
ln -sTf $root_profile /root/.guix-profile
echo 'PATH=$PATH:$HOME/.guix-profile/bin' >> /root/.profile

echo "Configuring PATH in profile for all users"
echo 'PATH=$PATH:$HOME/.guix-profile/bin' > /etc/profile.d/guix.sh
echo 'export PATH' >> /etc/profile.d/guix.sh

echo "Setting up build group and users"
groupadd --system guixbuild
for i in $(seq -w 1 $BUSERS)
do
    useradd --system -G guixbuild -s $(which nologin) -c "Guix build user $i" "guixbuilder$i"
done

echo "Setting up guix-daemon"
case $INIT in
    systemd)
	echo "Setting up Systemd service..."
	if [ -f /etc/systemd/system/guix-daemon.service ]
	then
	    rm /etc/systemd/system/guix-daemon.service
	fi
	ln -s /root/.guix-profile/lib/systemd/system/guix-daemon.service /etc/systemd/system/
	systemctl start guix-daemon && systemctl enable guix-daemon
	;;
    upstart)
	echo "Setting up Upstart service..."
	if [ -f /etc/init/guix-daemon.conf ]
	then
	    rm /etc/init/guix-daemon.conf
	fi
	ln -s /root/.guix-profile/lib/upstart/system/guix-daemon.conf /etc/init/
	start guix-daemon
	;;
    manual)
	echo "Starting guix-daemon in background process"
	guix-daemon --build-users-group guixbuild &
esac

echo "Authorizing substitutes from hydra.gnu.org..."
source ~/.profile
guix archive --authorize $root_profile/share/guix/hydra.gnu.org.pub
echo "Installing glibc locales..."
guix package -i glibc-utf8-locales && export GUIX_LOCPATH=~/.guix-profile/lib/locale
