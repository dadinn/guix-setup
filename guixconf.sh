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
	*)
	    usage
	    exit -1
	    ;;
    esac
done

### GUIX CONFIGURATION

GUIX_PROFILE=/var/guix/profiles/per-user/root/current-guix

echo "Adding info pages..."
INFO_DIR="/usr/local/share/info"
if [ ! -d $INFO_DIR ]
then
    mkdir -p $INFO_DIR
fi

for i in $GUIX_PROFILE/share/info/*
do
    ln -sf $i $INFO_DIR
done

. $GUIX_PROFILE/etc/profile


echo "Configuring PATH with GUIX user profiles..."
cat > /etc/profile.d/guix.sh << 'EOF'
export GUIX_PROFILE=$HOME/.guix-profile
export GUIX_LOCPATH=$GUIX_PROFILE/lib/locale
export PATH=$HOME/.config/guix/current/bin${PATH:+:}$PATH
. $GUIX_PROFILE/etc/profile
EOF

echo "Setting up build group and users..."
groupadd --system guixbuild
for i in $(seq -w 1 $BUSERS)
do
    useradd --system -G guixbuild -s $(which nologin) -c "Guix build user $i" "guixbuilder$i"
done

echo "Setting up guix-daemon..."
case $INIT in
    systemd)
	cp $GUIX_PROFILE/lib/systemd/system/guix-daemon.service /etc/systemd/system/
	systemctl enable guix-daemon
	systemctl start guix-daemon
	echo "Configured systemd service!"
	;;
    upstart)
	cp $GUIX_PROFILE/lib/upstart/system/guix-daemon.conf /etc/init/
	start guix-daemon
	echo "Configured upstart service!"
	;;
    *)
	$GUIX_PROFILE/guix-daemon --build-users-group guixbuild &
	echo "Started guix-daemon background process!"
	;;
esac

echo "Making guix command available to all users..."
ln -sf $GUIX_PROFILE/bin/guix /usr/local/bin/

echo "Authorizing substitutes from hydra.gnu.org..."
guix archive --authorize < $GUIX_PROFILE/share/guix/ci.guix.gnu.org.pub

echo "Updating GUIX binaries..."
guix pull

echo "Updating GUIX packages..."
guix package -u

echo "Installing glibc UTF-8 locales..."
guix package -i glibc-utf8-locales
