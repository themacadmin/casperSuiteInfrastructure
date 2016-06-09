# Casper Suite Infrastructure
These are scripts of other items that help keep Casper Suite infrastructure running to my specifications and preferences.

## dpSync.bash
Syncs a non-master distribution point from the master distribution point.

Tested on OS X v10.7-10.11 and ubuntu 14.04.3.

### dpSyncLaunchDaemon.plist
A LaunchDaemon to run dpSync.bash

I name this com.company.dpSync.plist and place it in /Library/LaunchDaemons/

Got a Linux DP? Run dpSync.bash via cron.

## createLinuxAfpDp
Create a Casper Suite distribution point on ubuntu 14.04.3

### Tested Sections

* Redirect output to log file
* Install netatalk 3.1.6
* Create and configure shared directory, accounts, and permissions
* Share $sharePath
* Create Distribution Point in JSS

### Untested Sections

* create ssh key
* replicate from master
* write cron job to replicate from master at 23:00 local time daily

### Unimplemented Sections

* write local script to replicate from master
