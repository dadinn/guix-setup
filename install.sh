#!/bin/bash

# TODO check if these commands are available:
# gpg wget tar (with xz-utils)

function usage {
    cat <<EOF
Set up the GNU Guix package manager

USAGE:

$0 OPTIONS...

Valid options are:

-v Guix version to use (default 0.12.0).

-a SYSARCH
Guix system architecture to use (default x86_64-linux).

Valid architectures are:
armhf-linux
i686-linux
mips64el-linux
x86_64-linux

-k keyserver to use for importing PGP keys (default gpg.mit.edu)

-i key id to use to fetch public PGP key

-r PATH
Use PATH as root directory to set up Guix under (default /tmp/root).

-t PATH
Use PATH to use for temporary files (default /tmp/guix).

-f
Flag to force overwrite existing Guix directories.
EOF
}
       
while getopts ':v:s:k:i:r:tfh' opt;
do
    case $opt in
	v)
	    VERSION=$OPTARG
	    ;;
	s)
	    SYSTEM=$OPTARG
	    ;;
	k)
	    KEYSERVER=$OPTARG
	    ;;
	i)
	    KEYID=$OPTARG
	    ;;
	t)
	    TMP_DIR=$OPTARG
	    ;;
	r)
	    ROOT_DIR=$OPTARG
	    ;;
	f)
	    FORCE='true'
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

TMP_DIR=${TMP_DIR:-/tmp/guix}
ROOT_DIR=${ROOT_DIR:-/tmp/root}
VERSION=${VERSION:-0.12.0}
SYSTEM=${SYSTEM:-x86_64-linux}
KEYSERVER=${KEYSERVER:-pgp.mit.edu}
KEYID=${KEYID:-BCA689B636553801C3C6215019A5888235FACAC}

if [[ ! -d $TMP_DIR ]]
then
    mkdir -p $TMP_DIR
fi

cd $TMP_DIR

filename="guix-binary-$VERSION.$SYSTEM.tar.xz"

if [[ ! -f $filename ]];
then
    wget ftp://alpha.gnu.org/gnu/guix/$filename
    wget ftp://alpha.gnu.org/gnu/guix/$filename.sig
    gpg --keyserver $KEYSERVER --recv-keys $KEYID
    gpg --verify $filename.sig
fi


tar --warning=no-timestamp -xf $filename
mv var/guix $ROOT_DIR/var
mv gnu $ROOT_DIR

#ln -sf /var/guix/profiles/per-user/root/guix-profile ~root/.guix-profile
#ln -s ~/root/.guix-profile/lib/systemd/system/guix-daemon.service /etc/systemd/systemd



# rm -rf $TMP_DIR
