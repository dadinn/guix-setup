#!/bin/sh

BUSERS=10
INIT=systemd

usage() {
    cat <<EOF

USAGE:

$0 OPTIONS...

Valid options are:

-n NUMBER
Number of Guix build users to create (default $BUSERS).

-i TYPE
Init system to set up guix-daemon for (default $INIT).
Valid values are: systemd, upstart.
EOF
}

while getopts 'n:i:h' opt
do
    case $opt in
	n)
	    BUSERS=$OPTARG
	    ;;
	i)
	    case $OPTARG in
	        systemd|upstart|manual)
	            INIT=$OPTARG
	            ;;
	        *)
	            echo
                    echo "ERROR: invalid argument for option -i: $OPTARG"
	            usage
	            error -1
	            ;;
	    esac
	    ;;
	h)
	    echo "Configure Guix installation"
	    usage
	    exit 0
	    ;;
	:)
	    echo "MISSING ARGUMENT FOR OPTION: $OPTARG" >&2
	    exit -1
	    ;;
	?)
	    echo "INVALID OPTION: $OPTARG" >&2
	    exit -1
	    ;;
	*)
	    usage
	    exit -1
	    ;;
    esac
done

### GUIX CONFIGURATION

root_profile=/var/guix/profiles/per-user/root/guix-profile

echo "Adding info pages..."

if [ ! -d /usr/local/share/info ]
then
    mkdir -p /usr/local/share/info
fi

for i in $root_profile/share/info/*
do
    ln -sf $i /usr/local/share/info/
done

echo "Setting up profile for root user..."
ln -sTf $root_profile /root/.guix-profile

echo "Configuring PATH with GUIX user profiles..."
echo 'export PATH=$PATH:$HOME/.guix-profile/bin' > /etc/profile.d/guix.sh
echo 'export GUIX_LOCPATH=$HOME/.guix-profile/lib/locale' >> /etc/profile.d/guix.sh
source /etc/profile.d/guix.sh

echo "Setting up build group and users..."
groupadd --system guixbuild
for i in $(seq -w 1 $BUSERS)
do
    useradd --system -G guixbuild -s $(which nologin) -c "Guix build user $i" "guixbuilder$i"
done

echo "Setting up guix-daemon..."
case $INIT in
    systemd)
	echo "Setting up systemd service..."
	ln -sf /root/.guix-profile/lib/systemd/system/guix-daemon.service /etc/systemd/system/
	systemctl enable guix-daemon && systemctl start guix-daemon
	;;
    upstart)
	echo "Setting up upstart service..."
	if [ -f /etc/init/guix-daemon.conf ]
	then
	    rm /etc/init/guix-daemon.conf
	fi
	ln -s /root/.guix-profile/lib/upstart/system/guix-daemon.conf /etc/init/
	start guix-daemon
	;;
    *)
	echo "Starting guix-daemon in background process"
	guix-daemon --build-users-group guixbuild &
	;;
esac

echo "Authorizing substitutes from hydra.gnu.org..."
guix archive --authorize < $root_profile/share/guix/hydra.gnu.org.pub

echo "Installing glibc locales..."
guix package -i glibc-utf8-locales
