#!/bin/sh


# Copyright (c) 2004-2015 Electric Sheep Fencing, LLC. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgment:
#    "This product includes software developed by the pfSense Project
#    for use in the pfSense® software distribution. (http://www.pfsense.org/).
#
# 4. The names "pfSense" and "pfSense Project" must not be used to
#    endorse or promote products derived from this software without
#    prior written permission. For written permission, please contact
#    coreteam@pfsense.org.
#
# 5. Products derived from this software may not be called "pfSense"
#    nor may "pfSense" appear in their names without prior written
#    permission of the Electric Sheep Fencing, LLC.
#
# 6. Redistributions of any form whatsoever must retain the following
#    acknowledgment:
#
# "This product includes software developed by the pfSense Project
# for use in the pfSense software distribution (http://www.pfsense.org/).
#
# THIS SOFTWARE IS PROVIDED BY THE pfSense PROJECT ``AS IS'' AND ANY
# EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE pfSense PROJECT OR
# ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

# Script is a simple wrapper around pfSense-upgrade. It is called from pkg_install.php to perform an
# installation or remval.
# FIFO is set up, log files named 

message () {
if ( $VERBOSE ) ; then
	echo "$1"
fi
}

usage () {
	echo "pfSense-upgrade-GUI.sh [flags] [-i || -r] PACKAGE_NAME"
	echo "Allows the web GUI to invoke the package installation script"
	echo "  -f : Force (Ignore lockfile)"
	echo "  -h : This help"
	echo "  -r : Install package"
	echo "  -i : Remove package"
	echo "  -v : Verbose"
}

if [ $# -lt 2 ] ; then
	echo "Usage: inst.sh [-i || -r] PACKAGE"
	echo "e.g.: inst.sh -i pfSense-pkg-sudo"
fi

VERBOSE=false
FORCE=false

while getopts fhirv opt; do
	case ${opt} in
		f)
			FORCE=true
			;;
		h)
			usage
			exit 0
			;;
		i)
			ACTION="-i"
			;;
		r)
			ACTION="-r"
			;;
		v)
			VERBOSE=true
			;;
		*)
			echo "Error: Unsupported option $(opt)"
			usage
			exit 1
			;;
	esac
done

shift $((OPTIND-1))
PKG=$1

if [ $ACTION == "-i" ] ; then
	message "Installing $PKG"
elif [ $ACTION == "-r" ] ; then
	message "Removing $PKG"
fi

UPDATEINPROGRESS=2
LOCKFILE=/tmp/pkg-upgate_GUI.lck
LOGFILE="webgui-log.txt"
FIFO=/tmp/upgr.fifo
JSONFILE="/cf/conf/webgui-log.json"

if [ -e $LOCKFILE ] ; then
	eval $(stat -s $LOCKFILE)
	NOW=`date +%s`
	let AGE="$NOW-$st_ctime" >/dev/null

	if [ $AGE -lt 300 ] && ( ! $FORCE ) ; then
		message "Update in progress!"
		exit $UPDATEINPROGRESS
	else
		message "Removing stale lockfile $INPROGRESS"
		rm -f $INPROGRESS
	fi
fi

touch $LOCKFILE

if [ -e $FIFO ] ; then
	rm $FIFO 2>/dev/null
fi

mkfifo $FIFO

# Capture the JSON progress status and send it to the file we are watching
tail -f $FIFO >$JSONFILE &
TAILPID=$!

message "Calling pfSense-upgrade with -l $LOGFILE -p $FIFO $ACTION $PKG"

/usr/local/sbin/pfSense-upgrade -l $LOGFILE -p $FIFO $ACTION $PKG >/dev/null

kill $TAILPID
rm $FIFO 2>/dev/null
rm $LOCKFILE

exit 0