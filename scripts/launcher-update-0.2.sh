#!/bin/sh

INSTALLER=$1
PW="frontrow"
REMOUNT=0

echo "Installing file $INSTALLER"

# check that disk-image exists
if [ -e $INSTALLER ]; then

 # Check if / is mounted read only
 if mount | grep ' on / '  | grep -q 'read-only'; then
  REMOUNT=1
  echo $PW | sudo -S /sbin/mount -uw /
 fi

 #  install new launcher
 echo $PW | sudo -S chmod +x $INSTALLER
 echo $PW | sudo -S $INSTALLER -- install /

 #sync to disk, just in case...
 /bin/sync

 #remove the download
 rm $INSTALLER 

 # remount root as we found it
 if [ "$REMOUNT" = "1" ]; then
  echo $PW | sudo -S /sbin/mount -ur /
 fi

 # restart finder
 kill `ps awx | grep [F]inder | awk '{print $1}'`
 
 exit 0
fi
echo "Failed to find installer $INSTALLER"
exit -1

