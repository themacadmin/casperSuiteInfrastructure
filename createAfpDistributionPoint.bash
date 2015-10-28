#!/bin/bash
#
##########################################################################################
#
# Header begins
#
##########################################################################################
#
# Copyright (c) 2015, Miles A. Leacy IV.  All rights reserved.
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
#	createAfpDistributionPoint.bash -- creates an AFP distribution point on ubuntu 14.04.3
#
# Usage
#	sudo createAfpDistributionPoint.bash
#
# Description
#	This script will:
#	* redirect output to a log file
#	* install and start netatalk 3.1.6
#	* create a directory to share
#	* create a read only account
#	* create a read/write account
#	* create a group called afpwrite
#	* add the read/write account to the afpwrite group
#	* recursively change the POSIX group on the shared directory to afpwrite
#	* add the read/write account to the afpwrite group
#	* give the POSIX group write permissions to the share
#	* configure netatalk to share the intended directory
#	* restart netatalk
#	* add the AFP server to the JSS as a Distribution Point
#	** assumes the ubuntu system is configured with a correct fqdn
#	* replicate from the master distribution point
#	* write local script to replicate from master Distribution Point
#	* write chron job to replicate from master at 23:00 local time
#
##########################################################################################
#
# History
#
#	Version: 1.0
#
#	- Created by Miles A. Leacy IV on 2015 10 19
#
##########################################################################################
#
# Header ends
#
##########################################################################################

##########################################################################################
#
# Declare Variables
#
##########################################################################################

# Log file
logFile="/var/log/distributionPointCreation.log"

# Shared directory and accounts
sharePath="/CasperShare"
readUser="readAcct"
readPass="read123"
writeUser="writeAcct"
writePass="write123"
writeGroup="afpWrite"

# AFP share name
shareName="CasperShare"

# JSS
server="https://jss.company.com"
port="8443"
jssAcct="jssAdminUser"
jssPass="jss1234"

# Distribution point info
name=`hostname`
ipAddress=`hostname --fqdn`
isMaster=false
connectionType=AFP
sharePort=548

# Master distribution point info
masterUser="adminuser"
masterPass="admin1234"
masterServer="master.server.corp"
masterPath="/CasperShare"
syncLogFile="/var/log/casperDpSync.log"

##########################################################################################
#
# Redirect output to log file begins
#
##########################################################################################

# Close STDOUT file descriptor
exec 1<&-
# Close STDERR FD
exec 2<&-

# Open STDOUT as $logFile file for read and write.
exec 1<>$logFile

# Redirect STDERR to STDOUT
exec 2>&1

errorExit() {
    echo "There was an error: $?"
    echo "Sync will exit"
    exit 1
}

echo "logging enabled"

##########################################################################################
#
# Redirect output to log file ends
#
##########################################################################################

##########################################################################################
#
# Install netatalk 3.1.6 begins
#
##########################################################################################

# Update system
apt-get update

# Install dependencies
apt-get -y install autoconf libtool automake build-essential libevent-dev libssl-dev libgcrypt11-dev libkrb5-dev libpam0g-dev libwrap0-dev libdb-dev libtdb-dev libmysqlclient-dev libavahi-client-dev libacl1-dev libldap2-dev libcrack2-dev systemtap-sdt-dev libdbus-1-dev libdbus-glib-1-dev libglib2.0-dev tracker libtracker-sparql-0.16-dev libtracker-miner-0.16-dev git

# Make a dev directory in ~
cd ~
mkdir dev
cd dev

# Get netatalk 3.1.6
git clone git://git.code.sf.net/p/netatalk/code netatalk
cd netatalk
git checkout netatalk-3-1-6

# Configure & Install
./bootstrap
./configure --with-init-style=debian-sysv --without-libevent --without-tdb --with-cracklib --enable-krbV-uam --with-pam-confdir=/etc/pam.d --with-dbus-sysconf-dir=/etc/dbus-1/system.d --with-tracker-pkgconfig-version=0.16
make
make install

##########################################################################################
#
# Install netatalk 3.1.6 ends
#
##########################################################################################

##########################################################################################
#
# Create and configure shared directory, accounts, and permissions begins
#
##########################################################################################

# Create shared directory
mkdir "$sharePath"

# Create accounts
useradd --gid 50 -s /bin/bash "$readUser"
useradd --gid 50 -s /bin/bash "$writeUser"

# Set passwords
echo "$readUser":"$readPass" | chpasswd
echo "$writeUser":"$writePass" | chpasswd

# Create write group
groupadd "$writeGroup"

# Put write user in write group
usermod -g "$writeGroup" "$writeUser"

# Change POSIX group on share to write group
chgrp -R "$writeGroup" "$sharePath"

# Give write group write permissions on share
chmod -R g+w "$sharePath"

##########################################################################################
#
# Create and configure shared directory, accounts, and permissions ends
#
##########################################################################################

##########################################################################################
#
# Share $sharePath begins
#
##########################################################################################

# Add $sharePath to /usr/local/etc/afp.conf
echo "" >> /usr/local/etc/afp.conf
echo "[${shareName}]" >> /usr/local/etc/afp.conf
echo " path = ${sharePath}" >> /usr/local/etc/afp.conf
echo " valid users = ${readUser} ${writeUser}" >> /usr/local/etc/afp.conf

# Restart netatalk
sudo service netatalk restart

##########################################################################################
#
# Share $sharePath ends
#
##########################################################################################

##########################################################################################
#
# Create Distribution Point in JSS begins
#
##########################################################################################

# Construct XML
apiDpXml="<distribution_point><name>${name}</name><ip_address>${ipAddress}</ip_address><is_master>${isMaster}</is_master><connection_type>${connectionType}</connection_type><share_name>${shareName}</share_name><share_port>${sharePort}</share_port><read_only_username>${readUser}</read_only_username><read_only_password>${readPass}</read_only_password><read_write_username>${writeUser}</read_write_username><read_write_password>${writePass}</read_write_password></distribution_point>"

# POST to JSS
curl -sS -k -i -u "$jssAcct":"$jssPass" -X POST -H "Content-Type: text/xml" -d "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>${apiDpXml}" ${server}:${port}/JSSResource/distributionpoints/id/0

##########################################################################################
#
# Create Distribution Point in JSS ends
#
##########################################################################################

##########################################################################################
#
# create ssh key begins *** NOT TESTED ***
#
##########################################################################################

# create SSH key
ssh-keygen -t rsa -N ""

# install sshpass
apt-get -y install sshpass

sshMasterPass="'$masterPass'"

# send SSH key to master DP
sshpass -p ${sshMasterPass} scp ~/.ssh/id_rsa.pub ${masterUser}@${masterServer}:~/.ssh/authorized_keys

##########################################################################################
#
# create ssh key ends
#
##########################################################################################

##########################################################################################
#
# replicate from master begins *** NOT TESTED ***
#
##########################################################################################

/usr/bin/rsync -tprv --progress ${masterUser}@${masterServer}:${masterPath} ${sharePath} --exclude=".*" || errorExit

##########################################################################################
#
# replicate from master ends
#
##########################################################################################

##########################################################################################
#
# write local script to replicate from master Distribution Point begins
# *** NOT FINISHED ***
# *** NOT TESTED ***
#
##########################################################################################

mkdir -p /var/lib/casperDpSync

cat >/var/lib/casperDpSync/casperDpSync.bash <<EOF
#/bin/bash
# put the rest of the script here
# use this script's variables to create the casperDpSync.bash script
EOF

chmod a+x /var/lib/casperDpSync/casperDpSync.bash

##########################################################################################
#
# write local script to replicate from master Distribution Point ends
#
##########################################################################################

##########################################################################################
#
# write chron job to replicate from master at 23:00 local time daily begins
# *** NOT TESTED ***
#
##########################################################################################

# dump crontab to newCron
crontab -l > newCron
# echo replication job into newCron
echo "0 23 * * * /var/lib/casperDpSync/casperDpSync.bash" >> newCron
# install newCron
crontab newCron
rm newCron

##########################################################################################
#
# write chron job to replicate from master at 23:00 local time ends
#
##########################################################################################

exit 0
