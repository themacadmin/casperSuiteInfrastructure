#!/bin/bash
#
##########################################################################################
#
# Header begins
#
##########################################################################################
#
# Copyright (c) 2016, Miles A. Leacy IV.  All rights reserved.
#
#     This script may be copied, modified, and distributed freely as long as this header
#     remains intact and modifications are publicly shared with the Mac administrators'
#     community at large.
#
#     This script is provided "as is".  The author offers no warranty or guarantee of any
#     kind.
#
#     Use of this script is at your own risk.  The author takes no responsibility for loss
#     of use, loss of data, loss of job, loss of socks, the onset of armageddon, or any
#     other negative effects.
#
#     Test thoroughly in a lab environment before use on production systems.
#     When you think it's ok, test again.  When you're certain it's ok, test twice more.
#
##########################################################################################
#
# About This Script
#
# Name
#	casperDpSync.bash -- Syncs a local distribution point with the master distribution point.
#
# Usage
#	Sync
#		sudo casperDpSync.bash
#	Dry run
#		sudo casperDpSync.bash 1
#
# DESCRIPTION
#	Syncs a local distribution point with the master distribution point. This script runs
# on the secondary (non-master) distribution point.
#
#	Script output is logged to a log file defined in the Declare Variables section below.
#
#	The script will exit if rsync is already running. This is to prevent a buildup of sync
# duplicate tasks on slow WAN connections.
#
#	"Dry run mode" described above is useful for testing. A dry run allows you to verify
# that all your variables are correct and that the script is functioning before copying
# data.
#	
#
##########################################################################################
#
# History
#
#	Version: 1.0
#
#	- Created by Miles A. Leacy IV on 2016 06 07
#		- incorporates work by Bryson Tyrell
#
#
##########################################################################################
#
# Header ends
#
##########################################################################################
#
# Declare Variables
#
##########################################################################################

# masterUser is the user that will be used to access the files from the master
# distribution point.
masterUser="username"

# masterServer is the IP address or fqdn of the master distribution point server.
masterServer="masterdp.company.com"

# masterPath is the share path for the distribution point on $masterServer
masterPath="/CasperShare"

# localPath is the directory that contains your distribution point share on the system
# executing this script (do not use escape characters).
localPath="/Shared Items/"

# localOwner will be given POSIX ownership of the synced files.
localOwner="casperadmin"

# localGroup will be assigned as the POSIX group of the synced files.
localGroup="staff"

# Output from this script will be logged in syncLogFile 
syncLogFile="/var/log/casperDpSync.log"

# timestamp provides timestamps for logging.
timestamp=`date "+%Y-%m-%d %H:%M:%S"`

##########################################################################################
#
# Redirect output to log file begins
#
##########################################################################################

touch "$syncLogFile"
chmod a+r "$syncLogFile"

2>&1 | tee ${syncLogFile}

errorExit() {
    echo ${timestamp} "There was an error: $?"
    echo ${timestamp} "Sync will exit"
    exit 1
}

##########################################################################################
#
# Redirect output to log file ends
#
##########################################################################################

##########################################################################################
#
# bail if rsync is running begins
#
##########################################################################################

if ps ax | grep -v grep | grep rsync > /dev/null
then
    echo ${timestamp} "rsync already running, stopping replication. Will try again tomorrow."
    exit 0
else
    echo ${timestamp} "rsync is not running"
fi

##########################################################################################
#
# bail if rsync is running ends
#
##########################################################################################

##########################################################################################
#
# Distribution point sync begins
#
##########################################################################################

dryrun=$1

echo ${timestamp} "Starting rsync from Master Distribution Point..."
if [ "$dryrun" ]; then
    echo ${timestamp} "Script is running in 'dry-run' mode"
    /usr/bin/rsync -trv --progress ${masterUser}@${masterServer}:${masterPath} "${localPath}" --exclude=".*" --dry-run
    exit 0
else
    /usr/bin/rsync -trv --progress ${masterUser}@${masterServer}:${masterPath} "${localPath}" --exclude=".*" --delete --log-file="${syncLogFile}" || errorExit
fi

echo ${timestamp} "Setting file ownership to ${userx}:${groupy}"
/bin/chown ${userx}:${groupy} ${localPath}*/*

echo ${timestamp} "The Distribution Point sync is complete"

##########################################################################################
#
# Distribution point sync ends
#
##########################################################################################

exit 0
