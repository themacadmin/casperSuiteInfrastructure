# Casper Suite Infrastructure
These are scripts of other items that help keep Casper Suite infrastructure running to my specifications and preferences.

##

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
* write chron job to replicate from master at 23:00 local time daily

### Unimplemented Sections

* write local script to replicate from master
