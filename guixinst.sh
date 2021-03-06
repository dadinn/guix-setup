#!/bin/sh

VERSION=1.0.1
ARCH=x86_64-linux
KEYSERVER=pgp.mit.edu
KEYID=3CE464558A84FDC69DB40CFB090B11993D9AEBB5
TEMP_DIR=guix-temp
ROOT_DIR=guix-root

usage() {
    cat <<EOF
USAGE:

$0 OPTIONS...

Valid options are:

-v VERSION
Guix version to use (default $VERSION).

-a ARCH
Guix architecture of host system to use (default $ARCH).
Valid values are: armhf-linux, mips64el-linux, i686-linux, x86_64-linux.

-u URL
keyserver URL to use for importing GPG keys (default $KEYSERVER).

-k KEYID
Key id to use to fetch public GPG key (default $KEYID).

-r PATH
Use PATH for target root directory (by default $ROOT_DIR).

-t PATH
Use PATH for downloaded temporary files (default $TEMP_DIR).

-f
Force installation even if signature cannot be verified

-h
This usage help...

EOF
}

while getopts ':v:a:u:k:r:t:fh' opt
do
    case $opt in
	v)
	    VERSION=$OPTARG
	    ;;
	a)
	    case $OPTARG in
                x86_64-linux|i686-linux|mips64el-linux|armhf-linux)
                    ARCH=$OPTARG
                    ;;
                *)
                    echo "ERROR: Wrong argument for option -s: $OPTARG"
                    echo
                    usage
                    exit -1
                    ;;
            esac
	    ;;
	u)
	    KEYSERVER=$OPTARG
	    ;;
	k)
	    KEYID=$OPTARG
	    ;;
	r)
	    ROOT_DIR=$OPTARG
	    ;;
	t)
	    TEMP_DIR=$OPTARG
	    ;;
	f)
	    FORCE=1
	    ;;
	h)
            echo Set up the GNU Guix package manager on an existing Linux host system.
            echo
            usage
            exit 0
	    ;;
	*)
	    usage
	    exit -1
	    ;;
    esac
done

[ $(id -u) -eq 0 ] || { echo "This script must be run as root."; exit 1; }

### DOWNLOADING GUIX BINARIES

if [ ! -d $TEMP_DIR ]
then
    mkdir -p $TEMP_DIR
fi

filename="guix-binary-$VERSION.$ARCH.tar.xz"

if [ ! -f $TEMP_DIR/$filename ]
then
    wget -P $TEMP_DIR ftp://ftp.gnu.org/gnu/guix/$filename
fi

if [ ! -f $TEMP_DIR/$filename.sig ]
then
    wget -P $TEMP_DIR ftp://ftp.gnu.org/gnu/guix/$filename.sig
fi

if ! gpg --list-keys $KEYID 2> /dev/null
then
    if [ ${FORCE:-0} -eq 0 ]
    then
	echo Fetching GPG key...
	gpg --keyserver $KEYSERVER --recv-keys $KEYID 2> /dev/null
    fi
fi

echo "Verifying signature..."
if gpg --verify $TEMP_DIR/$filename.sig 2> /dev/null
then
    echo "Signature VERIFIED!"
else
    echo "Signature CANNOT BE VERIFIED!"
    [ ${FORCE:-0} -gt 0 ] || exit 1
fi

### SETTING UP GUIX

if [ ! -d $ROOT_DIR ]
then
    mkdir -p $ROOT_DIR
fi

echo "Extracting and installing Guix binaries..."
tar --warning=no-timestamp -x --file $TEMP_DIR/$filename --directory $ROOT_DIR


cp ./guixconf.sh $ROOT_DIR
echo "Copied configuration script under $ROOT_DIR"

read -p "Clean up temporary files? [y/N]" cleanup
case $cleanup in
    [yY])
	echo "Cleaning up temporary files..."
	rm -rf $TEMP_DIR
	;;
    *)
	echo "Skipped cleaning up temporary files"
	;;
esac
