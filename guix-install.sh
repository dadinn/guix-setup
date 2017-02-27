#!/bin/bash

# TODO check if these commands are available:
# gpg wget tar (with xz-utils)

source ./guix-defaults

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
-r PATH
Use PATH for target root directory (by default /).
-t PATH
Use PATH for downloaded temporary files (default /tmp/guix).
EOF
}
       
while getopts ':v:s:u:k:n:i:r:t:h' opt
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
	r)
	    ROOT_DIR=$OPTARG
	    ;;
	t)
	    TEMP_DIR=$OPTARG
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

if [[ ! -d $TEMP_DIR ]]
then
    mkdir -p $TEMP_DIR
fi

filename="guix-binary-$VERSION.$SYSTEM.tar.xz"

if [[ ! -f $TEMP_DIR/$filename ]]
then
    wget -P $TEMP_DIR ftp://alpha.gnu.org/gnu/guix/$filename
fi

if [[ ! -f $TEMP_DIR/$filename.sig ]]
then
    wget -P $TEMP_DIR ftp://alpha.gnu.org/gnu/guix/$filename.sig
fi

if ! gpg --list-keys $KEYID
then
    echo Fetching PGP key...
    gpg --keyserver $KEYSERVER --recv-keys $KEYID
fi

echo "Verifying signature..."
if gpg --verify $TEMP_DIR/$filename.sig
then
    echo "Signature VERIFIED!"
else
    echo "Signature CANNOT BE VERIFIED!"
    exit -1
fi

### SETTING UP GUIX

if [[ ! -d $ROOT_DIR ]]
then
    mkdir -p $ROOT_DIR
fi

echo "Extracting and installing Guix binaries..."
tar --warning=no-timestamp -x --file $TEMP_DIR/$filename --directory $ROOT_DIR

read -p "Clean up temporary files? [Y/n]" cleanup
case $cleanup in
    [nN])
	echo "Skipped cleaning up temporary files"
	;;
    *)
	echo "Cleaning up temporary files..."
	rm -rf $TEMP_DIR
	;;
esac


