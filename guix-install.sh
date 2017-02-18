#!/bin/bash

# TODO check if these commands are available:
# gpg wget tar (with xz-utils)

source guix-defaults.sh

function usage {
    cat <<EOF
Set up the GNU Guix package manager on an existing Linux host system.

USAGE:

$0 OPTIONS...

Valid options are:

-v VERSION
Guix version to use (default 0.12.0).
-s SYSARCH
Guix architecture and host system to use (default x86_64-linux).
Valid values are: armhf-linux, mips64el-linux, i686-linux, x86_64-linux.
-u URL
keyserver URL to use for importing PGP keys (default gpg.mit.edu).
-k KEYID
Key id to use to fetch public PGP key (default ending 235FACAC).
-n NUMBER
Number of Guix build users to create (default 10).
-i TYPE
Init system to set up guix-daemon for (default systemd).
Valid values are: systemd, upstart, manual.
-f
Flag to force overwriting existing Guix installation.
-t PATH
Use PATH for downloaded temporary files (default /tmp/guix).
EOF
}
       
while getopts ':v:s:u:k:n:i:tfh' opt;
do
    case $opt in
	v)
	    VERSION=$OPTARG
	    ;;
	s)
	    SYSTEM=$OPTARG
	    ;;
	u)
	    KEYSERVER=$OPTARG
	    ;;
	k)
	    KEYID=$OPTARG
	    ;;
	n)
	    BUSERS=$OPTARG
	    ;;
	i)
	    INIT=$OPTARG
	    ;;
	t)
	    TMP_DIR=$OPTARG
	    ;;
	f)
	    FORCE=1
	    ;;
	h)
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

### DOWNLOADING GUIX BINARIES

if [[ ! -d $TMP_DIR ]]
then
    mkdir -p $TMP_DIR
fi

cd $TMP_DIR

filename="guix-binary-$VERSION.$SYSTEM.tar.xz"

if [[ ! -f $filename ]]
then
    wget ftp://alpha.gnu.org/gnu/guix/$filename
fi

if [[ ! -f $filename.sig ]]
then
    wget ftp://alpha.gnu.org/gnu/guix/$filename.sig
fi

if ! gpg --list-keys $KEYID
then
    echo Fetching PGP key...
    gpg --keyserver $KEYSERVER --recv-keys $KEYID
fi

echo "Verifying signature..."
if gpg --verify $filename.sig
then
    echo "Signature VERIFIED!"
else
    echo "Signature CANNOT BE VERIFIED!"
    exit -1
fi

### SETTING UP GUIX

if [ ! -d $TMP_DIR/var/guix ] && [ ! -d $TMP_DIR/gnu ]
then
    echo "Extracting Guix binaries..."
    tar --warning=no-timestamp -xf $filename
fi

if [ -d /var/guix ]
then
    if [ $FORCE = 1 ]
    then
	rm -rf /var/guix
    else
	echo "ERROR: /var/guix directory already exists! Use -f flag to force overwriting it!"
	exit -1
    fi
fi

if [ -d /gnu ]
then
    if [ $FORCE = 1 ]
    then
	rm -rf /gnu
    else
	echo "ERROR: /gnu directory already exists! Use -f flag to force overwriting it!"
	exit -1
    fi
fi

echo "Installing binaries under /gnu and /var/guix ..."
mv var/guix /var
mv gnu /

echo "Cleaning up temporary files..."
rm -rf $TMP_DIR

